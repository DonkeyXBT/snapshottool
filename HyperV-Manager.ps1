#Requires -Version 5.1
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    HyperV Toolkit - Hyper-V Server & Snapshot Management Tool
.DESCRIPTION
    A comprehensive GUI tool for managing Hyper-V virtual machines and snapshots:
    - Server Management: View IP addresses, memory, storage, and CPU information
    - Snapshot Management: View, filter, and delete VM snapshots across nodes
    - Search & Filtering: Real-time search and state/age filtering
    - Export to CSV: Export data for reporting
    - Favorites: Mark and filter favorite VMs
    - Notifications: Microsoft Teams webhook integration
.NOTES
    Version: 4.0
#>

# Get script path
$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }

# Import modules
Import-Module (Join-Path $scriptPath "Modules\Common.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\ServerManagement.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\SnapshotManagement.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\UIComponents.psm1") -Force

# Initialize logging, config, and favorites
Initialize-LogFile -ScriptPath $scriptPath
Initialize-Config -ScriptPath $scriptPath
Initialize-Favorites -ScriptPath $scriptPath

# Global variables
$script:hyperVNodes = @()
$script:allVMs = @()
$script:allSnapshots = @()
$script:serverInfo = @()
$script:filteredServerInfo = @()
$script:filteredSnapshots = @()
$script:filteredVMs = @()
$script:runspace = $null
$script:powerShell = $null
$script:currentView = "menu"

# Create the main form and panels
$form = New-MainForm
$titleBar = New-CustomTitleBar -Form $form
$panelConnection = New-ConnectionPanel -Form $form
$panelMenu = New-MenuPanel
$panelServer = New-ServerManagementPanel
$panelSnapshot = New-SnapshotManagementPanel

$form.Controls.Add($titleBar)
$form.Controls.Add($panelConnection)
$form.Controls.Add($panelMenu)
$form.Controls.Add($panelServer)
$form.Controls.Add($panelSnapshot)

# Get references to controls
$textBoxNodes = Find-ControlByName -Parent $form -Name 'textBoxNodes'
$buttonConnect = Find-ControlByName -Parent $form -Name 'buttonConnect'
$buttonBackToMenu = Find-ControlByName -Parent $form -Name 'buttonBackToMenu'
$labelStatus = Find-ControlByName -Parent $form -Name 'labelStatus'
$buttonServerMgmt = Find-ControlByName -Parent $form -Name 'buttonServerMgmt'
$buttonSnapshotMgmt = Find-ControlByName -Parent $form -Name 'buttonSnapshotMgmt'

# Server Management controls
$buttonRefreshServer = Find-ControlByName -Parent $form -Name 'buttonRefreshServer'
$buttonExportServer = Find-ControlByName -Parent $form -Name 'buttonExportServer'
$textBoxSearchServer = Find-ControlByName -Parent $form -Name 'textBoxSearchServer'
$comboBoxFilterServer = Find-ControlByName -Parent $form -Name 'comboBoxFilterServer'
$checkBoxFavoritesServer = Find-ControlByName -Parent $form -Name 'checkBoxFavoritesServer'
$dataGridServer = Find-ControlByName -Parent $form -Name 'dataGridServer'
$labelSummaryServer = Find-ControlByName -Parent $form -Name 'labelSummaryServer'

# Snapshot Management controls
$buttonRefreshSnapshot = Find-ControlByName -Parent $form -Name 'buttonRefreshSnapshot'
$buttonExportSnapshot = Find-ControlByName -Parent $form -Name 'buttonExportSnapshot'
$textBoxSearchVM = Find-ControlByName -Parent $form -Name 'textBoxSearchVM'
$textBoxSearchSnapshot = Find-ControlByName -Parent $form -Name 'textBoxSearchSnapshot'
$comboBoxAgeFilter = Find-ControlByName -Parent $form -Name 'comboBoxAgeFilter'
$dataGridSnapshots = Find-ControlByName -Parent $form -Name 'dataGridSnapshots'
$listBoxVMs = Find-ControlByName -Parent $form -Name 'listBoxVMs'
$buttonDelete = Find-ControlByName -Parent $form -Name 'buttonDelete'
$buttonSelectAll = Find-ControlByName -Parent $form -Name 'buttonSelectAll'
$buttonDeselectAll = Find-ControlByName -Parent $form -Name 'buttonDeselectAll'
$labelSummary = Find-ControlByName -Parent $form -Name 'labelSummary'

# Initialize cache files and nodes history
Initialize-CacheFiles -ScriptPath $scriptPath
Initialize-NodesHistory -ScriptPath $scriptPath

# Load recent nodes into the textbox
$recentNodes = Get-RecentNodes -ScriptPath $scriptPath -Count 1
if ($recentNodes.Count -gt 0) {
    $textBoxNodes.Text = $recentNodes -join ', '
}

# Apply modern scrollbars to DataGridViews and ListBox
Add-ModernScrollbar -DataGrid $dataGridServer -ParentPanel $panelServer
Add-ModernScrollbar -DataGrid $dataGridSnapshots -ParentPanel $panelSnapshot

# Find the sidebar panel for the ListBox scrollbar
$sidebarPanel = $null
foreach ($ctrl in $panelSnapshot.Controls) {
    if ($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Controls['listBoxVMs']) {
        $sidebarPanel = $ctrl
        break
    }
    # Check nested controls
    foreach ($nested in $ctrl.Controls) {
        if ($nested.Name -eq 'listBoxVMs') {
            $sidebarPanel = $ctrl
            break
        }
    }
}
if ($sidebarPanel) {
    Add-ModernListBoxScrollbar -ListBox $listBoxVMs -ParentPanel $sidebarPanel
}

# Timer for background operations
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed') {
        try {
            $result = $script:powerShell.EndInvoke($script:runspace)
            $buttonConnect.Enabled = $true

            if ($result -and $result.Success) {
                $script:allVMs = $result.VMs
                $script:allSnapshots = $result.Snapshots
                $script:serverInfo = $result.ServerInfo

                # Save snapshots to cache
                if ($script:allSnapshots.Count -gt 0) {
                    Save-SnapshotsCache -Snapshots $script:allSnapshots -ScriptPath $scriptPath
                }

                Write-Log "Successfully loaded $($script:allVMs.Count) VMs and $($script:allSnapshots.Count) snapshots" "SUCCESS"

                $buttonServerMgmt.Enabled = $true
                $buttonSnapshotMgmt.Enabled = $true
                $buttonBackToMenu.Enabled = $true

                Update-Status -StatusLabel $labelStatus -Message "Connected successfully to $($script:hyperVNodes.Count) node(s) - $($script:allVMs.Count) VMs found" -Color "Green"

                # Refresh current view if showing cached data
                if ($script:currentView -eq "server" -and $script:serverInfo.Count -gt 0) {
                    $script:filteredServerInfo = $script:serverInfo
                    Refresh-ServerGrid
                }
                elseif ($script:currentView -eq "snapshot" -and $script:allSnapshots.Count -gt 0) {
                    $script:filteredSnapshots = $script:allSnapshots
                    Refresh-SnapshotGrid
                }
            }
            else {
                Update-Status -StatusLabel $labelStatus -Message "Failed to load data" -Color "Red"
            }
        }
        catch {
            Update-Status -StatusLabel $labelStatus -Message "Error processing results: $($_.Exception.Message)" -Color "Red"
            $buttonConnect.Enabled = $true
        }
        finally {
            if ($script:powerShell -ne $null) {
                $script:powerShell.Dispose()
                $script:powerShell = $null
            }
            $script:runspace = $null
            $timer.Stop()
        }
    }
})

# Function to show specific panel
function Show-Panel {
    param([string]$PanelName)

    $panelMenu.Visible = $false
    $panelServer.Visible = $false
    $panelSnapshot.Visible = $false

    switch ($PanelName) {
        "menu" {
            $panelMenu.Visible = $true
            $script:currentView = "menu"
        }
        "server" {
            $panelServer.Visible = $true
            $script:currentView = "server"
            Load-ServerManagementData
        }
        "snapshot" {
            $panelSnapshot.Visible = $true
            $script:currentView = "snapshot"
            Load-SnapshotManagementData
        }
    }
}

# Apply server filters
function Apply-ServerFilters {
    $searchText = $textBoxSearchServer.Text
    if ($searchText -eq 'Search VMs...') { $searchText = '' }
    $stateFilter = $comboBoxFilterServer.SelectedItem
    $favoritesOnly = $checkBoxFavoritesServer.Checked

    $script:filteredServerInfo = $script:serverInfo | Where-Object {
        $matchesSearch = $true
        $matchesState = $true
        $matchesFavorites = $true

        if ($searchText) {
            $matchesSearch = ($_.VMName -like "*$searchText*") -or ($_.IPAddresses -like "*$searchText*") -or ($_.Node -like "*$searchText*") -or ($_.GuestOS -like "*$searchText*")
        }

        if ($stateFilter -and $stateFilter -ne 'All States') {
            $matchesState = $_.State -eq $stateFilter
        }

        if ($favoritesOnly) {
            $matchesFavorites = Test-IsFavorite -Node $_.Node -VMName $_.VMName
        }

        $matchesSearch -and $matchesState -and $matchesFavorites
    }

    Refresh-ServerGrid
}

# Refresh server grid
function Refresh-ServerGrid {
    $dataTable = New-Object System.Data.DataTable
    [void]$dataTable.Columns.Add("Fav", [string])
    [void]$dataTable.Columns.Add("Node", [string])
    [void]$dataTable.Columns.Add("VM Name", [string])
    [void]$dataTable.Columns.Add("State", [string])
    [void]$dataTable.Columns.Add("Operating System", [string])
    [void]$dataTable.Columns.Add("IP Addresses", [string])
    [void]$dataTable.Columns.Add("Memory Total (GB)", [string])
    [void]$dataTable.Columns.Add("Memory Used (GB)", [string])
    [void]$dataTable.Columns.Add("Memory Available (GB)", [string])
    [void]$dataTable.Columns.Add("CPU Count", [string])
    [void]$dataTable.Columns.Add("Disk Size (GB)", [string])
    [void]$dataTable.Columns.Add("Disk Used (GB)", [string])

    foreach ($server in $script:filteredServerInfo) {
        $isFav = if (Test-IsFavorite -Node $server.Node -VMName $server.VMName) { "*" } else { "" }
        [void]$dataTable.Rows.Add(
            $isFav,
            $server.Node,
            $server.VMName,
            $server.State,
            $server.GuestOS,
            $server.IPAddresses,
            $server.MemoryTotalGB,
            $server.MemoryUsedGB,
            $server.MemoryAvailableGB,
            $server.ProcessorCount,
            $server.DiskSizeGB,
            $server.DiskUsedGB
        )
    }

    $dataGridServer.DataSource = $dataTable
    $labelSummaryServer.Text = "Showing $($script:filteredServerInfo.Count) of $($script:serverInfo.Count) VMs"
}

# Apply snapshot filters
function Apply-SnapshotFilters {
    $searchText = $textBoxSearchSnapshot.Text
    if ($searchText -eq 'Search snapshots...') { $searchText = '' }
    $ageFilter = $comboBoxAgeFilter.SelectedItem

    $script:filteredSnapshots = $script:allSnapshots | Where-Object {
        $matchesSearch = $true
        $matchesAge = $true

        if ($searchText) {
            $matchesSearch = ($_.SnapshotName -like "*$searchText*") -or ($_.VMName -like "*$searchText*") -or ($_.Node -like "*$searchText*")
        }

        if ($ageFilter -and $ageFilter -ne 'All Ages') {
            switch ($ageFilter) {
                'Older than 7 days' { $matchesAge = $_.AgeDays -gt 7 }
                'Older than 30 days' { $matchesAge = $_.AgeDays -gt 30 }
                'Older than 90 days' { $matchesAge = $_.AgeDays -gt 90 }
            }
        }

        $matchesSearch -and $matchesAge
    }

    Refresh-SnapshotGrid
}

# Apply VM list filters
function Apply-VMListFilters {
    $searchText = $textBoxSearchVM.Text
    if ($searchText -eq 'Search VMs...') { $searchText = '' }

    $script:filteredVMs = $script:allVMs | Where-Object {
        if ($searchText) {
            ($_.Name -like "*$searchText*") -or ($_.Node -like "*$searchText*") -or ($_.DisplayName -like "*$searchText*")
        } else {
            $true
        }
    }

    $listBoxVMs.Items.Clear()
    foreach ($vmData in $script:filteredVMs) {
        $displayText = $vmData.DisplayName
        if (Test-IsFavorite -Node $vmData.Node -VMName $vmData.Name) {
            $displayText = "* " + $displayText
        }
        [void]$listBoxVMs.Items.Add($displayText)
    }
}

# Refresh snapshot grid
function Refresh-SnapshotGrid {
    if ($script:filteredSnapshots.Count -eq 0) {
        $labelSummary.Text = "No snapshots match the current filter"
        $buttonDelete.Enabled = $false
        $buttonSelectAll.Enabled = $false
        $buttonDeselectAll.Enabled = $false
        $dataGridSnapshots.DataSource = $null
        return
    }

    $dataTable = New-Object System.Data.DataTable
    [void]$dataTable.Columns.Add("Node", [string])
    [void]$dataTable.Columns.Add("VM Name", [string])
    [void]$dataTable.Columns.Add("Snapshot Name", [string])
    [void]$dataTable.Columns.Add("Creation Time", [string])
    [void]$dataTable.Columns.Add("Age", [string])
    [void]$dataTable.Columns.Add("Age (Days)", [double])

    foreach ($snapshot in $script:filteredSnapshots) {
        [void]$dataTable.Rows.Add(
            $snapshot.Node,
            $snapshot.VMName,
            $snapshot.SnapshotName,
            $snapshot.CreationTime.ToString("yyyy-MM-dd HH:mm:ss"),
            $snapshot.Age,
            $snapshot.AgeDays
        )
    }

    $dataGridSnapshots.DataSource = $dataTable

    $oldSnapshots = ($script:filteredSnapshots | Where-Object { $_.AgeDays -gt 7 }).Count
    $labelSummary.Text = "Showing $($script:filteredSnapshots.Count) of $($script:allSnapshots.Count) snapshots | Older than 7 days: $oldSnapshots"

    $buttonDelete.Enabled = $true
    $buttonSelectAll.Enabled = $true
    $buttonDeselectAll.Enabled = $true
}

# Load server management data
function Load-ServerManagementData {
    if ($script:serverInfo.Count -eq 0) {
        Update-Status -StatusLabel $labelStatus -Message "Loading server information..." -Color "Blue"
        Get-ServerInformation
        return
    }

    $script:filteredServerInfo = $script:serverInfo
    Refresh-ServerGrid
    Update-Status -StatusLabel $labelStatus -Message "Loaded information for $($script:serverInfo.Count) VMs" -Color "Green"
}

# Load snapshot management data
function Load-SnapshotManagementData {
    $script:filteredVMs = $script:allVMs
    Apply-VMListFilters

    if ($script:allSnapshots.Count -eq 0) {
        Update-Status -StatusLabel $labelStatus -Message "No snapshots found" -Color "Green"
        $labelSummary.Text = "Total: 0 snapshots"
        $buttonDelete.Enabled = $false
        $buttonSelectAll.Enabled = $false
        $buttonDeselectAll.Enabled = $false
        $dataGridSnapshots.DataSource = $null
        return
    }

    $script:filteredSnapshots = $script:allSnapshots
    Refresh-SnapshotGrid
    Update-Status -StatusLabel $labelStatus -Message "Loaded $($script:allSnapshots.Count) snapshots from $($script:allVMs.Count) VMs" -Color "Green"
}

# Get server information in background with real-time progressive updates
function Get-ServerInformation {
    Update-Status -StatusLabel $labelStatus -Message "Gathering server information (0/$($script:allVMs.Count) VMs)..." -Color "Blue"
    $buttonRefreshServer.Enabled = $false

    # Create synchronized hashtable for progress tracking
    $script:serverSyncHash = [hashtable]::Synchronized(@{
        TotalVMs = $script:allVMs.Count
        ProcessedVMs = 0
        ServerInfo = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        IsComplete = $false
        CurrentVM = ""
        LastDisplayedCount = 0
    })

    $script:powerShell = [PowerShell]::Create()
    [void]$script:powerShell.AddScript({
        param($VMData, $ModulePath, $SyncHash)
        Import-Module $ModulePath -Force
        return Get-ServerInformationProgressive -VMData $VMData -SyncHash $SyncHash
    })
    [void]$script:powerShell.AddArgument($script:allVMs)
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\ServerManagement.psm1"))
    [void]$script:powerShell.AddArgument($script:serverSyncHash)

    $script:runspace = $script:powerShell.BeginInvoke()

    $script:serverInfoTimer = New-Object System.Windows.Forms.Timer
    $script:serverInfoTimer.Interval = 300  # Faster updates for real-time feel
    $script:serverInfoTimer.Add_Tick({
        $syncHash = $script:serverSyncHash

        # Update progress in status bar
        if ($syncHash.ProcessedVMs -gt 0) {
            $currentVM = if ($syncHash.CurrentVM) { " - $($syncHash.CurrentVM)" } else { "" }
            Update-Status -StatusLabel $labelStatus -Message "Loading server info ($($syncHash.ProcessedVMs)/$($syncHash.TotalVMs) VMs)$currentVM..." -Color "Blue"
        }

        # Progressively update the grid with new data
        $currentCount = $syncHash.ServerInfo.Count
        if ($currentCount -gt $syncHash.LastDisplayedCount) {
            # New data available - update the display
            $script:serverInfo = @($syncHash.ServerInfo.ToArray())
            $script:filteredServerInfo = $script:serverInfo
            Refresh-ServerGrid

            $syncHash.LastDisplayedCount = $currentCount
        }

        # Check if complete
        if ($syncHash.IsComplete -or ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed')) {
            try {
                if ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed') {
                    $null = $script:powerShell.EndInvoke($script:runspace)
                }

                # Final update with all data
                $script:serverInfo = @($syncHash.ServerInfo.ToArray())
                $script:filteredServerInfo = $script:serverInfo
                $buttonRefreshServer.Enabled = $true

                # Save to cache
                if ($script:serverInfo.Count -gt 0) {
                    Save-ServerInfoCache -ServerInfo $script:serverInfo -ScriptPath $scriptPath
                }

                Refresh-ServerGrid
                Update-Status -StatusLabel $labelStatus -Message "Loaded information for $($script:serverInfo.Count) VMs" -Color "Green"
            }
            catch {
                Update-Status -StatusLabel $labelStatus -Message "Error loading server information: $($_.Exception.Message)" -Color "Red"
                $buttonRefreshServer.Enabled = $true
            }
            finally {
                if ($script:powerShell -ne $null) {
                    $script:powerShell.Dispose()
                    $script:powerShell = $null
                }
                $script:runspace = $null
                if ($script:serverInfoTimer -ne $null) {
                    $script:serverInfoTimer.Stop()
                    $script:serverInfoTimer.Dispose()
                    $script:serverInfoTimer = $null
                }
            }
        }
    })
    $script:serverInfoTimer.Start()
}

# Refresh snapshot data with real-time progressive updates
function Refresh-SnapshotData {
    if ($script:allVMs.Count -eq 0) { return }

    Update-Status -StatusLabel $labelStatus -Message "Loading snapshots (0/$($script:allVMs.Count) VMs)..." -Color "Blue"
    $buttonRefreshSnapshot.Enabled = $false

    # Create synchronized hashtable for progress tracking
    $script:snapshotSyncHash = [hashtable]::Synchronized(@{
        TotalVMs = $script:allVMs.Count
        ProcessedVMs = 0
        Snapshots = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        IsComplete = $false
        CurrentVM = ""
        LastDisplayedCount = 0
    })

    $script:powerShell = [PowerShell]::Create()
    [void]$script:powerShell.AddScript({
        param($VMData, $ModulePath, $SyncHash)
        Import-Module $ModulePath -Force
        return Get-VMSnapshotsProgressive -VMData $VMData -SyncHash $SyncHash
    })
    [void]$script:powerShell.AddArgument($script:allVMs)
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\SnapshotManagement.psm1"))
    [void]$script:powerShell.AddArgument($script:snapshotSyncHash)

    $script:runspace = $script:powerShell.BeginInvoke()

    $script:snapshotTimer = New-Object System.Windows.Forms.Timer
    $script:snapshotTimer.Interval = 300  # Faster updates for real-time feel
    $script:snapshotTimer.Add_Tick({
        $syncHash = $script:snapshotSyncHash

        # Update progress in status bar
        if ($syncHash.ProcessedVMs -gt 0) {
            $currentVM = if ($syncHash.CurrentVM) { " - $($syncHash.CurrentVM)" } else { "" }
            $snapshotCount = $syncHash.Snapshots.Count
            Update-Status -StatusLabel $labelStatus -Message "Loading snapshots ($($syncHash.ProcessedVMs)/$($syncHash.TotalVMs) VMs, $snapshotCount found)$currentVM..." -Color "Blue"
        }

        # Progressively update the grid with new data
        $currentCount = $syncHash.Snapshots.Count
        if ($currentCount -gt $syncHash.LastDisplayedCount) {
            # New data available - update the display
            $script:allSnapshots = @($syncHash.Snapshots.ToArray())
            $script:filteredSnapshots = $script:allSnapshots
            Refresh-SnapshotGrid

            $syncHash.LastDisplayedCount = $currentCount
        }

        # Check if complete
        if ($syncHash.IsComplete -or ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed')) {
            try {
                if ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed') {
                    $null = $script:powerShell.EndInvoke($script:runspace)
                }

                # Final update with all data
                $script:allSnapshots = @($syncHash.Snapshots.ToArray())
                $script:filteredSnapshots = $script:allSnapshots
                $buttonRefreshSnapshot.Enabled = $true

                # Save to cache
                if ($script:allSnapshots.Count -gt 0) {
                    Save-SnapshotsCache -Snapshots $script:allSnapshots -ScriptPath $scriptPath
                }

                Load-SnapshotManagementData
                Update-Status -StatusLabel $labelStatus -Message "Loaded $($script:allSnapshots.Count) snapshots from $($script:allVMs.Count) VMs" -Color "Green"
            }
            catch {
                Update-Status -StatusLabel $labelStatus -Message "Error loading snapshots: $($_.Exception.Message)" -Color "Red"
                $buttonRefreshSnapshot.Enabled = $true
            }
            finally {
                if ($script:powerShell -ne $null) {
                    $script:powerShell.Dispose()
                    $script:powerShell = $null
                }
                $script:runspace = $null
                if ($script:snapshotTimer -ne $null) {
                    $script:snapshotTimer.Stop()
                    $script:snapshotTimer.Dispose()
                    $script:snapshotTimer = $null
                }
            }
        }
    })
    $script:snapshotTimer.Start()
}

# Placeholder text management for search boxes (dark theme colors - improved visibility)
$script:PlaceholderColor = [System.Drawing.Color]::FromArgb(130, 140, 160)
$script:ActiveTextColor = [System.Drawing.Color]::FromArgb(237, 237, 245)

$textBoxSearchServer.Add_GotFocus({
    if ($textBoxSearchServer.Text -eq 'Search VMs...') {
        $textBoxSearchServer.Text = ''
        $textBoxSearchServer.ForeColor = $script:ActiveTextColor
    }
})
$textBoxSearchServer.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($textBoxSearchServer.Text)) {
        $textBoxSearchServer.Text = 'Search VMs...'
        $textBoxSearchServer.ForeColor = $script:PlaceholderColor
    }
})
# Debounced search - waits 200ms after last keystroke before filtering
$script:serverSearchTimer = New-Object System.Windows.Forms.Timer
$script:serverSearchTimer.Interval = 200
$script:serverSearchTimer.Add_Tick({
    $script:serverSearchTimer.Stop()
    Apply-ServerFilters
})
$textBoxSearchServer.Add_TextChanged({
    $script:serverSearchTimer.Stop()
    $script:serverSearchTimer.Start()
})

$textBoxSearchVM.Add_GotFocus({
    if ($textBoxSearchVM.Text -eq 'Search VMs...') {
        $textBoxSearchVM.Text = ''
        $textBoxSearchVM.ForeColor = $script:ActiveTextColor
    }
})
$textBoxSearchVM.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($textBoxSearchVM.Text)) {
        $textBoxSearchVM.Text = 'Search VMs...'
        $textBoxSearchVM.ForeColor = $script:PlaceholderColor
    }
})
$script:vmSearchTimer = New-Object System.Windows.Forms.Timer
$script:vmSearchTimer.Interval = 200
$script:vmSearchTimer.Add_Tick({
    $script:vmSearchTimer.Stop()
    Apply-VMListFilters
})
$textBoxSearchVM.Add_TextChanged({
    $script:vmSearchTimer.Stop()
    $script:vmSearchTimer.Start()
})

$textBoxSearchSnapshot.Add_GotFocus({
    if ($textBoxSearchSnapshot.Text -eq 'Search snapshots...') {
        $textBoxSearchSnapshot.Text = ''
        $textBoxSearchSnapshot.ForeColor = $script:ActiveTextColor
    }
})
$textBoxSearchSnapshot.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($textBoxSearchSnapshot.Text)) {
        $textBoxSearchSnapshot.Text = 'Search snapshots...'
        $textBoxSearchSnapshot.ForeColor = $script:PlaceholderColor
    }
})
$script:snapshotSearchTimer = New-Object System.Windows.Forms.Timer
$script:snapshotSearchTimer.Interval = 200
$script:snapshotSearchTimer.Add_Tick({
    $script:snapshotSearchTimer.Stop()
    Apply-SnapshotFilters
})
$textBoxSearchSnapshot.Add_TextChanged({
    $script:snapshotSearchTimer.Stop()
    $script:snapshotSearchTimer.Start()
})

# Filter change events
$comboBoxFilterServer.Add_SelectedIndexChanged({ Apply-ServerFilters })
$checkBoxFavoritesServer.Add_CheckedChanged({ Apply-ServerFilters })
$comboBoxAgeFilter.Add_SelectedIndexChanged({ Apply-SnapshotFilters })

# Context menu for server grid (modern dark theme)
$contextMenuServer = New-ModernContextMenu -MenuItems @(
    @{ Text = "VM Actions"; Name = "menuHeader"; Tag = "header"; Enabled = $false }
    @{ Type = "Separator" }
    @{ Text = "  Add to Favorites"; Name = "menuAddFav" }
    @{ Text = "  Remove from Favorites"; Name = "menuRemoveFav"; Tag = "danger" }
)

# Get references to the menu items by name
$menuItemAddFav = $contextMenuServer.Items['menuAddFav']
$menuItemRemoveFav = $contextMenuServer.Items['menuRemoveFav']

# Dynamically show/hide items and update header when menu opens
$contextMenuServer.Add_Opening({
    param($sender, $e)
    if ($dataGridServer.SelectedRows.Count -eq 0) {
        $e.Cancel = $true
        return
    }

    $row = $dataGridServer.SelectedRows[0]
    $node = $row.Cells["Node"].Value
    $vmName = $row.Cells["VM Name"].Value
    $isFav = Test-IsFavorite -Node $node -VMName $vmName

    # Update header to show VM name
    $headerItem = $sender.Items['menuHeader']
    if ($headerItem) { $headerItem.Text = $vmName }

    # Show relevant option based on favorite state
    $menuItemAddFav.Visible = -not $isFav
    $menuItemRemoveFav.Visible = $isFav
})

$menuItemAddFav.Add_Click({
    if ($dataGridServer.SelectedRows.Count -gt 0) {
        $row = $dataGridServer.SelectedRows[0]
        $node = $row.Cells["Node"].Value
        $vmName = $row.Cells["VM Name"].Value
        if (Add-Favorite -Node $node -VMName $vmName) {
            Update-Status -StatusLabel $labelStatus -Message "Added $vmName to favorites" -Color "Green"
            Apply-ServerFilters
        }
    }
})

$menuItemRemoveFav.Add_Click({
    if ($dataGridServer.SelectedRows.Count -gt 0) {
        $row = $dataGridServer.SelectedRows[0]
        $node = $row.Cells["Node"].Value
        $vmName = $row.Cells["VM Name"].Value
        Remove-Favorite -Node $node -VMName $vmName
        Update-Status -StatusLabel $labelStatus -Message "Removed $vmName from favorites" -Color "Green"
        Apply-ServerFilters
    }
})

# Right-click should select the row under the cursor before showing menu
$dataGridServer.Add_CellMouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right -and $e.RowIndex -ge 0) {
        $sender.ClearSelection()
        $sender.Rows[$e.RowIndex].Selected = $true
        $sender.CurrentCell = $sender.Rows[$e.RowIndex].Cells[0]
    }
})

$dataGridServer.ContextMenuStrip = $contextMenuServer

# Export buttons
$buttonExportServer.Add_Click({
    if ($dataGridServer.DataSource) {
        $success = Export-ToCSV -DataTable $dataGridServer.DataSource -DefaultFileName "ServerInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        if ($success) {
            [System.Windows.Forms.MessageBox]::Show("Data exported successfully!", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
})

$buttonExportSnapshot.Add_Click({
    if ($dataGridSnapshots.DataSource) {
        $success = Export-ToCSV -DataTable $dataGridSnapshots.DataSource -DefaultFileName "Snapshots_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        if ($success) {
            [System.Windows.Forms.MessageBox]::Show("Data exported successfully!", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
})

# Connect button
$buttonConnect.Add_Click({
    $nodeInput = $textBoxNodes.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($nodeInput)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please enter at least one Hyper-V node",
            "Input Required",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    $script:hyperVNodes = $nodeInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    # Validate node names (alphanumeric, hyphens, dots, underscores only)
    $invalidNodes = $script:hyperVNodes | Where-Object { $_ -notmatch '^[a-zA-Z0-9._-]+$' }
    if ($invalidNodes.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Invalid node name(s): $($invalidNodes -join ', ')`n`nNode names can only contain letters, numbers, dots, hyphens, and underscores.",
            "Invalid Input",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    Write-Log "Connecting to nodes: $($script:hyperVNodes -join ', ')" "INFO"

    # Save nodes to history
    Save-NodesHistory -Nodes $script:hyperVNodes -ScriptPath $scriptPath

    # Try to load from cache first for instant display
    $serverCache = Load-ServerInfoCache -ScriptPath $scriptPath
    $snapshotCache = Load-SnapshotsCache -ScriptPath $scriptPath

    $cacheLoaded = $false
    if ($serverCache.Success -and $serverCache.Data.Count -gt 0) {
        $script:serverInfo = $serverCache.Data
        $script:filteredServerInfo = $script:serverInfo
        $cacheLoaded = $true
        Write-Log "Loaded $($script:serverInfo.Count) VMs from server cache" "INFO"
    }

    if ($snapshotCache.Success -and $snapshotCache.Data.Count -gt 0) {
        $script:allSnapshots = $snapshotCache.Data
        $script:filteredSnapshots = $script:allSnapshots
        Write-Log "Loaded $($script:allSnapshots.Count) snapshots from cache" "INFO"
    }

    if ($cacheLoaded) {
        # Enable buttons with cached data while refreshing in background
        $buttonServerMgmt.Enabled = $true
        $buttonSnapshotMgmt.Enabled = $true
        $buttonBackToMenu.Enabled = $true

        $cacheAge = Get-CacheAge -CacheType 'ServerInfo' -ScriptPath $scriptPath
        Update-Status -StatusLabel $labelStatus -Message "Loaded from cache ($($cacheAge.AgeText)) - Refreshing in background..." -Color "Blue"
    } else {
        Update-Status -StatusLabel $labelStatus -Message "Connecting to nodes in background..." -Color "Blue"
        $buttonServerMgmt.Enabled = $false
        $buttonSnapshotMgmt.Enabled = $false
    }

    $script:allVMs = @()

    $buttonConnect.Enabled = $false

    $script:powerShell = [PowerShell]::Create()
    [void]$script:powerShell.AddScript({
        param($Nodes, $ServerModulePath, $SnapshotModulePath)

        Import-Module $ServerModulePath -Force
        Import-Module $SnapshotModulePath -Force

        $result = @{
            Success = $false
            VMs = @()
            Snapshots = @()
            ServerInfo = @()
            Errors = @()
        }

        $vmResult = Get-VMsFromNodes -Nodes $Nodes
        $result.VMs = $vmResult.VMs
        $result.Errors = $vmResult.Errors

        if ($result.VMs.Count -gt 0) {
            $result.Snapshots = Get-VMSnapshotsAsync -VMData $result.VMs
            $result.Success = $true
        }

        return $result
    })
    [void]$script:powerShell.AddArgument($script:hyperVNodes)
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\ServerManagement.psm1"))
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\SnapshotManagement.psm1"))

    $script:runspace = $script:powerShell.BeginInvoke()
    $timer.Start()
})

# Menu navigation buttons
$buttonServerMgmt.Add_Click({
    Write-Log "Navigating to Server Management" "INFO"
    Show-Panel "server"
})

$buttonSnapshotMgmt.Add_Click({
    Write-Log "Navigating to Snapshot Management" "INFO"
    Show-Panel "snapshot"
})

$buttonBackToMenu.Add_Click({
    Write-Log "Returning to main menu" "INFO"
    Show-Panel "menu"
})

# Refresh buttons
$buttonRefreshServer.Add_Click({
    Write-Log "Refreshing server information" "INFO"
    Get-ServerInformation
})

$buttonRefreshSnapshot.Add_Click({
    Write-Log "Refreshing snapshot data" "INFO"
    Refresh-SnapshotData
})

# Delete snapshot button
$buttonDelete.Add_Click({
    $selectedRows = $dataGridSnapshots.SelectedRows

    if ($selectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select at least one snapshot to delete",
            "No Selection",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to delete $($selectedRows.Count) snapshot(s)?`n`nThis action cannot be undone!",
        "Confirm Deletion",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $successCount = 0
        $failCount = 0
        $deletedSnapshots = @()

        Write-Log "Starting deletion of $($selectedRows.Count) snapshot(s)" "INFO"

        foreach ($row in $selectedRows) {
            $node = $row.Cells["Node"].Value
            $vmName = $row.Cells["VM Name"].Value
            $snapshotName = $row.Cells["Snapshot Name"].Value

            try {
                Update-Status -StatusLabel $labelStatus -Message "Deleting snapshot '$snapshotName' from VM '$vmName'..." -Color "Blue"

                $snapshotToDelete = $script:allSnapshots | Where-Object {
                    $_.Node -eq $node -and $_.VMName -eq $vmName -and $_.SnapshotName -eq $snapshotName
                } | Select-Object -First 1

                if ($snapshotToDelete) {
                    $deleteResult = Remove-VMSnapshotFromNode -Node $node -VMName $vmName -SnapshotName $snapshotName -SnapshotObject $snapshotToDelete.Snapshot

                    if ($deleteResult.Success) {
                        $successCount++
                        $deletedSnapshots += @{ Node = $node; VM = $vmName; Snapshot = $snapshotName }
                        Write-Log "Successfully deleted snapshot '$snapshotName' from VM '$vmName' on node '$node'" "SUCCESS"
                    } else {
                        $failCount++
                        Write-Log "Failed to delete snapshot '$snapshotName' from VM '$vmName' on node '$node': $($deleteResult.Error)" "ERROR"
                    }
                }
            }
            catch {
                $failCount++
                Write-Log "Failed to delete snapshot '$snapshotName' from VM '$vmName' on node '$node': $($_.Exception.Message)" "ERROR"
            }
        }

        if ($successCount -gt 0) {
            $snapshotDetails = $deletedSnapshots | ForEach-Object {
                "- **$($_.Snapshot)** from VM **$($_.VM)** on node **$($_.Node)**"
            }
            $teamsMessage = "**Deleted Snapshots: $successCount**`n`n" + ($snapshotDetails -join "`n")

            if ($failCount -gt 0) {
                $teamsMessage += "`n`n**Failed: $failCount snapshot(s)**"
            }

            $teamsMessage += "`n`n*Executed by: $env:USERNAME on $env:COMPUTERNAME*"
            Send-TeamsNotification -Title "Hyper-V Snapshots Deleted" -Message $teamsMessage -Color "00FF00"
        }

        if ($failCount -eq 0) {
            Update-Status -StatusLabel $labelStatus -Message "Successfully deleted $successCount snapshot(s)" -Color "Green"
            Write-Log "Deletion completed: $successCount succeeded" "SUCCESS"
            [System.Windows.Forms.MessageBox]::Show(
                "Successfully deleted $successCount snapshot(s)",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            Update-Status -StatusLabel $labelStatus -Message "Deleted $successCount snapshot(s), $failCount failed" -Color "Orange"
            Write-Log "Deletion completed: $successCount succeeded, $failCount failed" "WARNING"
            [System.Windows.Forms.MessageBox]::Show(
                "Deleted $successCount snapshot(s)`nFailed: $failCount",
                "Partial Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }

        Refresh-SnapshotData
    }
})

# Select/Deselect All buttons
$buttonSelectAll.Add_Click({ $dataGridSnapshots.SelectAll() })
$buttonDeselectAll.Add_Click({ $dataGridSnapshots.ClearSelection() })

# Show the form
Write-Log "Displaying main form" "INFO"
[void]$form.ShowDialog()
Write-Log "HyperV Toolkit closed" "INFO"
