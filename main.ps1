#Requires -Version 5.1
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Hyper-V VM Snapshot Management Tool
.DESCRIPTION
    A GUI tool to connect to Hyper-V hosts, view VMs, and manage VM snapshots
.NOTES
    Author: Claude
    Date: 2026-01-09
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Hyper-V Snapshot Management Tool'
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(1000, 600)

# Create labels and controls
$labelNodes = New-Object System.Windows.Forms.Label
$labelNodes.Location = New-Object System.Drawing.Point(10, 15)
$labelNodes.Size = New-Object System.Drawing.Size(150, 20)
$labelNodes.Text = 'Hyper-V Nodes:'
$form.Controls.Add($labelNodes)

# TextBox for Hyper-V nodes
$textBoxNodes = New-Object System.Windows.Forms.TextBox
$textBoxNodes.Location = New-Object System.Drawing.Point(160, 12)
$textBoxNodes.Size = New-Object System.Drawing.Size(400, 20)
$textBoxNodes.Text = 'localhost'
$form.Controls.Add($textBoxNodes)

# Help label
$labelHelp = New-Object System.Windows.Forms.Label
$labelHelp.Location = New-Object System.Drawing.Point(570, 15)
$labelHelp.Size = New-Object System.Drawing.Size(300, 20)
$labelHelp.Text = '(comma-separated for multiple nodes)'
$labelHelp.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($labelHelp)

# Connect button
$buttonConnect = New-Object System.Windows.Forms.Button
$buttonConnect.Location = New-Object System.Drawing.Point(880, 10)
$buttonConnect.Size = New-Object System.Drawing.Size(100, 25)
$buttonConnect.Text = 'Connect'
$form.Controls.Add($buttonConnect)

# Refresh button
$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Location = New-Object System.Drawing.Point(990, 10)
$buttonRefresh.Size = New-Object System.Drawing.Size(100, 25)
$buttonRefresh.Text = 'Refresh'
$buttonRefresh.Enabled = $false
$form.Controls.Add($buttonRefresh)

# Status label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(10, 45)
$labelStatus.Size = New-Object System.Drawing.Size(1100, 20)
$labelStatus.Text = 'Enter Hyper-V node(s) and click Connect'
$labelStatus.ForeColor = [System.Drawing.Color]::Blue
$form.Controls.Add($labelStatus)

# VM ListBox
$labelVMs = New-Object System.Windows.Forms.Label
$labelVMs.Location = New-Object System.Drawing.Point(10, 75)
$labelVMs.Size = New-Object System.Drawing.Size(200, 20)
$labelVMs.Text = 'Virtual Machines:'
$form.Controls.Add($labelVMs)

$listBoxVMs = New-Object System.Windows.Forms.ListBox
$listBoxVMs.Location = New-Object System.Drawing.Point(10, 100)
$listBoxVMs.Size = New-Object System.Drawing.Size(300, 500)
$listBoxVMs.SelectionMode = 'MultiExtended'
$form.Controls.Add($listBoxVMs)

# Snapshots DataGridView
$labelSnapshots = New-Object System.Windows.Forms.Label
$labelSnapshots.Location = New-Object System.Drawing.Point(320, 75)
$labelSnapshots.Size = New-Object System.Drawing.Size(200, 20)
$labelSnapshots.Text = 'VM Snapshots:'
$form.Controls.Add($labelSnapshots)

$dataGridSnapshots = New-Object System.Windows.Forms.DataGridView
$dataGridSnapshots.Location = New-Object System.Drawing.Point(320, 100)
$dataGridSnapshots.Size = New-Object System.Drawing.Size(860, 450)
$dataGridSnapshots.AllowUserToAddRows = $false
$dataGridSnapshots.AllowUserToDeleteRows = $false
$dataGridSnapshots.ReadOnly = $true
$dataGridSnapshots.SelectionMode = 'FullRowSelect'
$dataGridSnapshots.MultiSelect = $true
$dataGridSnapshots.AutoSizeColumnsMode = 'Fill'
$form.Controls.Add($dataGridSnapshots)

# Delete button
$buttonDelete = New-Object System.Windows.Forms.Button
$buttonDelete.Location = New-Object System.Drawing.Point(320, 560)
$buttonDelete.Size = New-Object System.Drawing.Size(150, 30)
$buttonDelete.Text = 'Delete Selected'
$buttonDelete.Enabled = $false
$buttonDelete.BackColor = [System.Drawing.Color]::IndianRed
$buttonDelete.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($buttonDelete)

# Select All button
$buttonSelectAll = New-Object System.Windows.Forms.Button
$buttonSelectAll.Location = New-Object System.Drawing.Point(480, 560)
$buttonSelectAll.Size = New-Object System.Drawing.Size(100, 30)
$buttonSelectAll.Text = 'Select All'
$buttonSelectAll.Enabled = $false
$form.Controls.Add($buttonSelectAll)

# Deselect All button
$buttonDeselectAll = New-Object System.Windows.Forms.Button
$buttonDeselectAll.Location = New-Object System.Drawing.Point(590, 560)
$buttonDeselectAll.Size = New-Object System.Drawing.Size(100, 30)
$buttonDeselectAll.Text = 'Deselect All'
$buttonDeselectAll.Enabled = $false
$form.Controls.Add($buttonDeselectAll)

# Summary label
$labelSummary = New-Object System.Windows.Forms.Label
$labelSummary.Location = New-Object System.Drawing.Point(320, 600)
$labelSummary.Size = New-Object System.Drawing.Size(860, 50)
$labelSummary.Text = ''
$form.Controls.Add($labelSummary)

# Global variables to store data
$script:hyperVNodes = @()
$script:allVMs = @()
$script:allSnapshots = @()

# Function to update status
function Update-Status {
    param([string]$Message, [string]$Color = 'Blue')
    $labelStatus.Text = $Message
    $labelStatus.ForeColor = [System.Drawing.Color]::FromName($Color)
    $form.Refresh()
}

# Function to get all VMs from nodes
function Get-AllVMs {
    param([array]$Nodes)

    $allVMs = @()

    foreach ($node in $Nodes) {
        try {
            Update-Status "Connecting to $node..." "Blue"

            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $vms = Get-VM -ErrorAction Stop
            } else {
                $vms = Get-VM -ComputerName $node -ErrorAction Stop
            }

            foreach ($vm in $vms) {
                $allVMs += [PSCustomObject]@{
                    Node = $node
                    VM = $vm
                    Name = $vm.Name
                    State = $vm.State
                    DisplayName = "$($vm.Name) [$($vm.State)] - $node"
                }
            }

            Update-Status "Successfully connected to $node - Found $($vms.Count) VMs" "Green"
        }
        catch {
            Update-Status "Error connecting to ${node}: $($_.Exception.Message)" "Red"
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to connect to ${node}:`n$($_.Exception.Message)",
                "Connection Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }

    return $allVMs
}

# Function to get all snapshots
function Get-AllSnapshots {
    param([array]$VMData)

    $allSnapshots = @()
    $totalSnapshots = 0

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM

            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $snapshots = Get-VMSnapshot -VM $vm -ErrorAction Stop
            } else {
                $snapshots = Get-VMSnapshot -VMName $vm.Name -ComputerName $node -ErrorAction Stop
            }

            foreach ($snapshot in $snapshots) {
                $age = (Get-Date) - $snapshot.CreationTime
                $ageText = ""

                if ($age.TotalDays -ge 1) {
                    $ageText = "{0} days, {1} hours" -f [Math]::Floor($age.TotalDays), $age.Hours
                } elseif ($age.TotalHours -ge 1) {
                    $ageText = "{0} hours, {1} minutes" -f [Math]::Floor($age.TotalHours), $age.Minutes
                } else {
                    $ageText = "{0} minutes" -f [Math]::Floor($age.TotalMinutes)
                }

                $allSnapshots += [PSCustomObject]@{
                    Node = $node
                    VMName = $vm.Name
                    SnapshotName = $snapshot.Name
                    CreationTime = $snapshot.CreationTime
                    Age = $ageText
                    AgeDays = [Math]::Round($age.TotalDays, 2)
                    Snapshot = $snapshot
                }

                $totalSnapshots++
            }
        }
        catch {
            Write-Warning "Error getting snapshots for $($vm.Name): $($_.Exception.Message)"
        }
    }

    return $allSnapshots
}

# Function to refresh snapshot data
function Refresh-SnapshotData {
    if ($script:allVMs.Count -eq 0) {
        return
    }

    Update-Status "Loading snapshots..." "Blue"
    $dataGridSnapshots.DataSource = $null

    # Get snapshots for all VMs
    $script:allSnapshots = Get-AllSnapshots -VMData $script:allVMs

    if ($script:allSnapshots.Count -eq 0) {
        Update-Status "No snapshots found" "Green"
        $labelSummary.Text = "Total: 0 snapshots"
        $buttonDelete.Enabled = $false
        $buttonSelectAll.Enabled = $false
        $buttonDeselectAll.Enabled = $false
    } else {
        # Create DataTable for display
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

        # Calculate statistics
        $oldSnapshots = ($script:allSnapshots | Where-Object { $_.AgeDays -gt 7 }).Count
        $totalSize = $script:allSnapshots.Count

        Update-Status "Loaded $totalSize snapshots" "Green"
        $labelSummary.Text = "Total: $totalSize snapshots | Older than 7 days: $oldSnapshots"

        $buttonDelete.Enabled = $true
        $buttonSelectAll.Enabled = $true
        $buttonDeselectAll.Enabled = $true
    }
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

    # Parse nodes
    $script:hyperVNodes = $nodeInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    Update-Status "Connecting to nodes..." "Blue"

    # Clear existing data
    $listBoxVMs.Items.Clear()
    $dataGridSnapshots.DataSource = $null
    $script:allVMs = @()
    $script:allSnapshots = @()

    # Get all VMs
    $script:allVMs = Get-AllVMs -Nodes $script:hyperVNodes

    if ($script:allVMs.Count -eq 0) {
        Update-Status "No VMs found" "Orange"
        $buttonRefresh.Enabled = $false
        return
    }

    # Populate VM list
    foreach ($vmData in $script:allVMs) {
        [void]$listBoxVMs.Items.Add($vmData.DisplayName)
    }

    Update-Status "Found $($script:allVMs.Count) VMs" "Green"
    $buttonRefresh.Enabled = $true

    # Load snapshots
    Refresh-SnapshotData
})

# Refresh button click event
$buttonRefresh.Add_Click({
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

        foreach ($row in $selectedRows) {
            $node = $row.Cells["Node"].Value
            $vmName = $row.Cells["VM Name"].Value
            $snapshotName = $row.Cells["Snapshot Name"].Value

            try {
                Update-Status "Deleting snapshot '$snapshotName' from VM '$vmName'..." "Blue"

                if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                    # Local deletion using snapshot object
                    $snapshotToDelete = $script:allSnapshots | Where-Object {
                        $_.Node -eq $node -and
                        $_.VMName -eq $vmName -and
                        $_.SnapshotName -eq $snapshotName
                    } | Select-Object -First 1

                    if ($snapshotToDelete) {
                        Remove-VMSnapshot -VMSnapshot $snapshotToDelete.Snapshot -Confirm:$false -ErrorAction Stop
                        $successCount++
                    }
                } else {
                    # Remote deletion using Invoke-Command
                    Invoke-Command -ComputerName $node -ScriptBlock {
                        param($VMName, $SnapshotName)
                        $snapshot = Get-VMSnapshot -VMName $VMName -Name $SnapshotName -ErrorAction Stop
                        Remove-VMSnapshot -VMSnapshot $snapshot -Confirm:$false -ErrorAction Stop
                    } -ArgumentList $vmName, $snapshotName -ErrorAction Stop
                    $successCount++
                }
            }
            catch {
                $failCount++
                Write-Warning "Failed to delete snapshot '$snapshotName': $($_.Exception.Message)"
            }
        }

        if ($failCount -eq 0) {
            Update-Status "Successfully deleted $successCount snapshot(s)" "Green"
            [System.Windows.Forms.MessageBox]::Show(
                "Successfully deleted $successCount snapshot(s)",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        } else {
            Update-Status "Deleted $successCount snapshot(s), $failCount failed" "Orange"
            [System.Windows.Forms.MessageBox]::Show(
                "Deleted $successCount snapshot(s)`nFailed: $failCount",
                "Partial Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }

        # Refresh the snapshot list
        Refresh-SnapshotData
    }
})

# Select All button click event
$buttonSelectAll.Add_Click({
    $dataGridSnapshots.SelectAll()
})

# Deselect All button click event
$buttonDeselectAll.Add_Click({
    $dataGridSnapshots.ClearSelection()
})

# Show the form
[void]$form.ShowDialog()
