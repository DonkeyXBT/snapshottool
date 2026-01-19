#Requires -Version 5.1
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Hyper-V Server Management and Snapshot Tool
.DESCRIPTION
    A comprehensive GUI tool to manage Hyper-V servers and VMs including:
    - Server Management: View IP addresses, memory, and storage information
    - Snapshot Management: View and delete VM snapshots
.NOTES
    Author: Claude
    Date: 2026-01-19
    Version: 2.0 (Modular)
#>

# Get script path
$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }

# Import modules
Import-Module (Join-Path $scriptPath "Modules\Common.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\ServerManagement.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\SnapshotManagement.psm1") -Force
Import-Module (Join-Path $scriptPath "Modules\UIComponents.psm1") -Force

# Initialize logging
Initialize-LogFile -ScriptPath $scriptPath

# Global variables
$script:hyperVNodes = @()
$script:allVMs = @()
$script:allSnapshots = @()
$script:serverInfo = @()
$script:runspace = $null
$script:powerShell = $null
$script:currentView = "menu"

# Create the main form and panels
$form = New-MainForm
$panelConnection = New-ConnectionPanel -Form $form
$panelMenu = New-MenuPanel
$panelServer = New-ServerManagementPanel
$panelSnapshot = New-SnapshotManagementPanel

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
$buttonRefreshServer = Find-ControlByName -Parent $form -Name 'buttonRefreshServer'
$buttonRefreshSnapshot = Find-ControlByName -Parent $form -Name 'buttonRefreshSnapshot'
$dataGridServer = Find-ControlByName -Parent $form -Name 'dataGridServer'
$dataGridSnapshots = Find-ControlByName -Parent $form -Name 'dataGridSnapshots'
$listBoxVMs = Find-ControlByName -Parent $form -Name 'listBoxVMs'
$buttonDelete = Find-ControlByName -Parent $form -Name 'buttonDelete'
$buttonSelectAll = Find-ControlByName -Parent $form -Name 'buttonSelectAll'
$buttonDeselectAll = Find-ControlByName -Parent $form -Name 'buttonDeselectAll'
$labelSummary = Find-ControlByName -Parent $form -Name 'labelSummary'

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

                Write-Log "Successfully loaded $($script:allVMs.Count) VMs and $($script:allSnapshots.Count) snapshots" "SUCCESS"

                $buttonServerMgmt.Enabled = $true
                $buttonSnapshotMgmt.Enabled = $true
                $buttonBackToMenu.Enabled = $true

                Update-Status -StatusLabel $labelStatus -Message "Connected successfully to $($script:hyperVNodes.Count) node(s) - $($script:allVMs.Count) VMs found" -Color "Green"
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

# Function to load server management data
function Load-ServerManagementData {
    if ($script:serverInfo.Count -eq 0) {
        Update-Status -StatusLabel $labelStatus -Message "Loading server information..." -Color "Blue"
        Get-ServerInformation
        return
    }

    $dataTable = New-Object System.Data.DataTable
    [void]$dataTable.Columns.Add("Node", [string])
    [void]$dataTable.Columns.Add("VM Name", [string])
    [void]$dataTable.Columns.Add("State", [string])
    [void]$dataTable.Columns.Add("IP Addresses", [string])
    [void]$dataTable.Columns.Add("Memory Total (GB)", [string])
    [void]$dataTable.Columns.Add("Memory Used (GB)", [string])
    [void]$dataTable.Columns.Add("Memory Available (GB)", [string])
    [void]$dataTable.Columns.Add("CPU Count", [string])
    [void]$dataTable.Columns.Add("Disk Size (GB)", [string])
    [void]$dataTable.Columns.Add("Disk Used (GB)", [string])

    foreach ($server in $script:serverInfo) {
        [void]$dataTable.Rows.Add(
            $server.Node,
            $server.VMName,
            $server.State,
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
    Update-Status -StatusLabel $labelStatus -Message "Loaded information for $($script:serverInfo.Count) VMs" -Color "Green"
}

# Function to load snapshot management data
function Load-SnapshotManagementData {
    $listBoxVMs.Items.Clear()
    foreach ($vmData in $script:allVMs) {
        [void]$listBoxVMs.Items.Add($vmData.DisplayName)
    }

    if ($script:allSnapshots.Count -eq 0) {
        Update-Status -StatusLabel $labelStatus -Message "No snapshots found" -Color "Green"
        $labelSummary.Text = "Total: 0 snapshots"
        $buttonDelete.Enabled = $false
        $buttonSelectAll.Enabled = $false
        $buttonDeselectAll.Enabled = $false
        $dataGridSnapshots.DataSource = $null
    } else {
        $dataTable = New-Object System.Data.DataTable
        [void]$dataTable.Columns.Add("Node", [string])
        [void]$dataTable.Columns.Add("VM Name", [string])
        [void]$dataTable.Columns.Add("Snapshot Name", [string])
        [void]$dataTable.Columns.Add("Creation Time", [string])
        [void]$dataTable.Columns.Add("Age", [string])
        [void]$dataTable.Columns.Add("Age (Days)", [double])

        foreach ($snapshot in $script:allSnapshots) {
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

        $oldSnapshots = ($script:allSnapshots | Where-Object { $_.AgeDays -gt 7 }).Count
        $totalSize = $script:allSnapshots.Count

        Update-Status -StatusLabel $labelStatus -Message "Loaded $totalSize snapshots from $($script:allVMs.Count) VMs" -Color "Green"
        $labelSummary.Text = "Total: $totalSize snapshots | Older than 7 days: $oldSnapshots"

        $buttonDelete.Enabled = $true
        $buttonSelectAll.Enabled = $true
        $buttonDeselectAll.Enabled = $true
    }
}

# Function to get server information in background
function Get-ServerInformation {
    Update-Status -StatusLabel $labelStatus -Message "Gathering server information in background..." -Color "Blue"
    $buttonRefreshServer.Enabled = $false

    $script:powerShell = [PowerShell]::Create()
    [void]$script:powerShell.AddScript({
        param($VMData, $ModulePath)
        Import-Module $ModulePath -Force
        return Get-ServerInformationAsync -VMData $VMData
    })
    [void]$script:powerShell.AddArgument($script:allVMs)
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\ServerManagement.psm1"))

    $script:runspace = $script:powerShell.BeginInvoke()

    $localTimer = New-Object System.Windows.Forms.Timer
    $localTimer.Interval = 500
    $localTimer.Add_Tick({
        if ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed') {
            try {
                $script:serverInfo = $script:powerShell.EndInvoke($script:runspace)
                $buttonRefreshServer.Enabled = $true
                Load-ServerManagementData
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
                $localTimer.Stop()
                $localTimer.Dispose()
            }
        }
    })
    $localTimer.Start()
}

# Function to refresh snapshot data
function Refresh-SnapshotData {
    if ($script:allVMs.Count -eq 0) { return }

    Update-Status -StatusLabel $labelStatus -Message "Loading snapshots..." -Color "Blue"
    $dataGridSnapshots.DataSource = $null
    $buttonRefreshSnapshot.Enabled = $false

    $script:powerShell = [PowerShell]::Create()
    [void]$script:powerShell.AddScript({
        param($VMData, $ModulePath)
        Import-Module $ModulePath -Force
        return Get-VMSnapshotsAsync -VMData $VMData
    })
    [void]$script:powerShell.AddArgument($script:allVMs)
    [void]$script:powerShell.AddArgument((Join-Path $scriptPath "Modules\SnapshotManagement.psm1"))

    $script:runspace = $script:powerShell.BeginInvoke()

    $localTimer = New-Object System.Windows.Forms.Timer
    $localTimer.Interval = 500
    $localTimer.Add_Tick({
        if ($script:powerShell -ne $null -and $script:powerShell.InvocationStateInfo.State -eq 'Completed') {
            try {
                $script:allSnapshots = $script:powerShell.EndInvoke($script:runspace)
                $buttonRefreshSnapshot.Enabled = $true
                Load-SnapshotManagementData
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
                $localTimer.Stop()
                $localTimer.Dispose()
            }
        }
    })
    $localTimer.Start()
}

# Connect button click event
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
    Write-Log "Connecting to nodes: $($script:hyperVNodes -join ', ')" "INFO"
    Update-Status -StatusLabel $labelStatus -Message "Connecting to nodes in background..." -Color "Blue"

    $script:allVMs = @()
    $script:allSnapshots = @()
    $script:serverInfo = @()

    $buttonConnect.Enabled = $false
    $buttonServerMgmt.Enabled = $false
    $buttonSnapshotMgmt.Enabled = $false

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

        # Get VMs from nodes
        $vmResult = Get-VMsFromNodes -Nodes $Nodes
        $result.VMs = $vmResult.VMs
        $result.Errors = $vmResult.Errors

        # Get snapshots
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

# Menu button click events
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

# Delete button click event
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

        # Send Teams notification
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
Write-Log "Hyper-V Server Management Tool closed" "INFO"
