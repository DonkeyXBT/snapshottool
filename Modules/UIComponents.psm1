# UIComponents.psm1 - UI component creation functions

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Hyper-V Server Management Tool'
    $form.Size = New-Object System.Drawing.Size(1400, 800)
    $form.StartPosition = 'CenterScreen'
    $form.MinimumSize = New-Object System.Drawing.Size(1200, 700)

    return $form
}

function New-ConnectionPanel {
    param([System.Windows.Forms.Form]$Form)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 0)
    $panel.Size = New-Object System.Drawing.Size(1400, 80)
    $panel.BorderStyle = 'FixedSingle'

    # Labels and textbox
    $labelNodes = New-Object System.Windows.Forms.Label
    $labelNodes.Location = New-Object System.Drawing.Point(10, 15)
    $labelNodes.Size = New-Object System.Drawing.Size(150, 20)
    $labelNodes.Text = 'Hyper-V Nodes:'
    $panel.Controls.Add($labelNodes)

    $textBoxNodes = New-Object System.Windows.Forms.TextBox
    $textBoxNodes.Location = New-Object System.Drawing.Point(160, 12)
    $textBoxNodes.Size = New-Object System.Drawing.Size(400, 20)
    $textBoxNodes.Text = 'localhost'
    $textBoxNodes.Name = 'textBoxNodes'
    $panel.Controls.Add($textBoxNodes)

    $labelHelp = New-Object System.Windows.Forms.Label
    $labelHelp.Location = New-Object System.Drawing.Point(570, 15)
    $labelHelp.Size = New-Object System.Drawing.Size(300, 20)
    $labelHelp.Text = '(comma-separated for multiple nodes)'
    $labelHelp.ForeColor = [System.Drawing.Color]::Gray
    $panel.Controls.Add($labelHelp)

    $buttonConnect = New-Object System.Windows.Forms.Button
    $buttonConnect.Location = New-Object System.Drawing.Point(880, 10)
    $buttonConnect.Size = New-Object System.Drawing.Size(100, 25)
    $buttonConnect.Text = 'Connect'
    $buttonConnect.Name = 'buttonConnect'
    $panel.Controls.Add($buttonConnect)

    $buttonBackToMenu = New-Object System.Windows.Forms.Button
    $buttonBackToMenu.Location = New-Object System.Drawing.Point(990, 10)
    $buttonBackToMenu.Size = New-Object System.Drawing.Size(120, 25)
    $buttonBackToMenu.Text = 'Back to Menu'
    $buttonBackToMenu.Enabled = $false
    $buttonBackToMenu.Name = 'buttonBackToMenu'
    $panel.Controls.Add($buttonBackToMenu)

    $labelStatus = New-Object System.Windows.Forms.Label
    $labelStatus.Location = New-Object System.Drawing.Point(10, 45)
    $labelStatus.Size = New-Object System.Drawing.Size(1300, 20)
    $labelStatus.Text = 'Enter Hyper-V node(s) and click Connect'
    $labelStatus.ForeColor = [System.Drawing.Color]::Blue
    $labelStatus.Name = 'labelStatus'
    $panel.Controls.Add($labelStatus)

    $panel.Name = 'panelConnection'
    return $panel
}

function New-MenuPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 80)
    $panel.Size = New-Object System.Drawing.Size(1400, 720)
    $panel.Visible = $true
    $panel.Name = 'panelMenu'

    $labelWelcome = New-Object System.Windows.Forms.Label
    $labelWelcome.Location = New-Object System.Drawing.Point(400, 100)
    $labelWelcome.Size = New-Object System.Drawing.Size(600, 40)
    $labelWelcome.Text = 'Hyper-V Server Management Tool'
    $labelWelcome.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
    $labelWelcome.TextAlign = 'MiddleCenter'
    $panel.Controls.Add($labelWelcome)

    $labelSubtitle = New-Object System.Windows.Forms.Label
    $labelSubtitle.Location = New-Object System.Drawing.Point(400, 150)
    $labelSubtitle.Size = New-Object System.Drawing.Size(600, 30)
    $labelSubtitle.Text = 'Connect to a Hyper-V node to begin'
    $labelSubtitle.Font = New-Object System.Drawing.Font("Arial", 12)
    $labelSubtitle.TextAlign = 'MiddleCenter'
    $labelSubtitle.ForeColor = [System.Drawing.Color]::Gray
    $panel.Controls.Add($labelSubtitle)

    $buttonServerMgmt = New-Object System.Windows.Forms.Button
    $buttonServerMgmt.Location = New-Object System.Drawing.Point(500, 250)
    $buttonServerMgmt.Size = New-Object System.Drawing.Size(400, 80)
    $buttonServerMgmt.Text = 'Server Management'
    $buttonServerMgmt.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $buttonServerMgmt.BackColor = [System.Drawing.Color]::LightBlue
    $buttonServerMgmt.Enabled = $false
    $buttonServerMgmt.Name = 'buttonServerMgmt'
    $panel.Controls.Add($buttonServerMgmt)

    $labelServerDesc = New-Object System.Windows.Forms.Label
    $labelServerDesc.Location = New-Object System.Drawing.Point(500, 335)
    $labelServerDesc.Size = New-Object System.Drawing.Size(400, 40)
    $labelServerDesc.Text = 'View server information: IP addresses, memory, and storage'
    $labelServerDesc.TextAlign = 'MiddleCenter'
    $labelServerDesc.ForeColor = [System.Drawing.Color]::Gray
    $panel.Controls.Add($labelServerDesc)

    $buttonSnapshotMgmt = New-Object System.Windows.Forms.Button
    $buttonSnapshotMgmt.Location = New-Object System.Drawing.Point(500, 400)
    $buttonSnapshotMgmt.Size = New-Object System.Drawing.Size(400, 80)
    $buttonSnapshotMgmt.Text = 'Snapshot Management'
    $buttonSnapshotMgmt.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $buttonSnapshotMgmt.BackColor = [System.Drawing.Color]::LightGreen
    $buttonSnapshotMgmt.Enabled = $false
    $buttonSnapshotMgmt.Name = 'buttonSnapshotMgmt'
    $panel.Controls.Add($buttonSnapshotMgmt)

    $labelSnapshotDesc = New-Object System.Windows.Forms.Label
    $labelSnapshotDesc.Location = New-Object System.Drawing.Point(500, 485)
    $labelSnapshotDesc.Size = New-Object System.Drawing.Size(400, 40)
    $labelSnapshotDesc.Text = 'View and manage VM snapshots'
    $labelSnapshotDesc.TextAlign = 'MiddleCenter'
    $labelSnapshotDesc.ForeColor = [System.Drawing.Color]::Gray
    $panel.Controls.Add($labelSnapshotDesc)

    return $panel
}

function New-ServerManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 80)
    $panel.Size = New-Object System.Drawing.Size(1400, 720)
    $panel.Visible = $false
    $panel.Name = 'panelServer'

    $labelServerTitle = New-Object System.Windows.Forms.Label
    $labelServerTitle.Location = New-Object System.Drawing.Point(10, 10)
    $labelServerTitle.Size = New-Object System.Drawing.Size(300, 30)
    $labelServerTitle.Text = 'Server Management'
    $labelServerTitle.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($labelServerTitle)

    $buttonRefreshServer = New-Object System.Windows.Forms.Button
    $buttonRefreshServer.Location = New-Object System.Drawing.Point(1240, 10)
    $buttonRefreshServer.Size = New-Object System.Drawing.Size(120, 30)
    $buttonRefreshServer.Text = 'Refresh'
    $buttonRefreshServer.Name = 'buttonRefreshServer'
    $panel.Controls.Add($buttonRefreshServer)

    $dataGridServer = New-Object System.Windows.Forms.DataGridView
    $dataGridServer.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridServer.Size = New-Object System.Drawing.Size(1350, 620)
    $dataGridServer.AllowUserToAddRows = $false
    $dataGridServer.AllowUserToDeleteRows = $false
    $dataGridServer.ReadOnly = $true
    $dataGridServer.SelectionMode = 'FullRowSelect'
    $dataGridServer.MultiSelect = $false
    $dataGridServer.AutoSizeColumnsMode = 'Fill'
    $dataGridServer.Name = 'dataGridServer'
    $panel.Controls.Add($dataGridServer)

    return $panel
}

function New-SnapshotManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 80)
    $panel.Size = New-Object System.Drawing.Size(1400, 720)
    $panel.Visible = $false
    $panel.Name = 'panelSnapshot'

    $labelSnapshotTitle = New-Object System.Windows.Forms.Label
    $labelSnapshotTitle.Location = New-Object System.Drawing.Point(10, 10)
    $labelSnapshotTitle.Size = New-Object System.Drawing.Size(300, 30)
    $labelSnapshotTitle.Text = 'Snapshot Management'
    $labelSnapshotTitle.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($labelSnapshotTitle)

    $labelVMs = New-Object System.Windows.Forms.Label
    $labelVMs.Location = New-Object System.Drawing.Point(10, 50)
    $labelVMs.Size = New-Object System.Drawing.Size(200, 20)
    $labelVMs.Text = 'Virtual Machines:'
    $panel.Controls.Add($labelVMs)

    $listBoxVMs = New-Object System.Windows.Forms.ListBox
    $listBoxVMs.Location = New-Object System.Drawing.Point(10, 75)
    $listBoxVMs.Size = New-Object System.Drawing.Size(300, 550)
    $listBoxVMs.SelectionMode = 'MultiExtended'
    $listBoxVMs.Name = 'listBoxVMs'
    $panel.Controls.Add($listBoxVMs)

    $labelSnapshots = New-Object System.Windows.Forms.Label
    $labelSnapshots.Location = New-Object System.Drawing.Point(320, 50)
    $labelSnapshots.Size = New-Object System.Drawing.Size(200, 20)
    $labelSnapshots.Text = 'VM Snapshots:'
    $panel.Controls.Add($labelSnapshots)

    $buttonRefreshSnapshot = New-Object System.Windows.Forms.Button
    $buttonRefreshSnapshot.Location = New-Object System.Drawing.Point(1240, 47)
    $buttonRefreshSnapshot.Size = New-Object System.Drawing.Size(120, 25)
    $buttonRefreshSnapshot.Text = 'Refresh'
    $buttonRefreshSnapshot.Name = 'buttonRefreshSnapshot'
    $panel.Controls.Add($buttonRefreshSnapshot)

    $dataGridSnapshots = New-Object System.Windows.Forms.DataGridView
    $dataGridSnapshots.Location = New-Object System.Drawing.Point(320, 75)
    $dataGridSnapshots.Size = New-Object System.Drawing.Size(1040, 480)
    $dataGridSnapshots.AllowUserToAddRows = $false
    $dataGridSnapshots.AllowUserToDeleteRows = $false
    $dataGridSnapshots.ReadOnly = $true
    $dataGridSnapshots.SelectionMode = 'FullRowSelect'
    $dataGridSnapshots.MultiSelect = $true
    $dataGridSnapshots.AutoSizeColumnsMode = 'Fill'
    $dataGridSnapshots.Name = 'dataGridSnapshots'
    $panel.Controls.Add($dataGridSnapshots)

    $buttonDelete = New-Object System.Windows.Forms.Button
    $buttonDelete.Location = New-Object System.Drawing.Point(320, 565)
    $buttonDelete.Size = New-Object System.Drawing.Size(150, 30)
    $buttonDelete.Text = 'Delete Selected'
    $buttonDelete.Enabled = $false
    $buttonDelete.BackColor = [System.Drawing.Color]::IndianRed
    $buttonDelete.ForeColor = [System.Drawing.Color]::White
    $buttonDelete.Name = 'buttonDelete'
    $panel.Controls.Add($buttonDelete)

    $buttonSelectAll = New-Object System.Windows.Forms.Button
    $buttonSelectAll.Location = New-Object System.Drawing.Point(480, 565)
    $buttonSelectAll.Size = New-Object System.Drawing.Size(100, 30)
    $buttonSelectAll.Text = 'Select All'
    $buttonSelectAll.Enabled = $false
    $buttonSelectAll.Name = 'buttonSelectAll'
    $panel.Controls.Add($buttonSelectAll)

    $buttonDeselectAll = New-Object System.Windows.Forms.Button
    $buttonDeselectAll.Location = New-Object System.Drawing.Point(590, 565)
    $buttonDeselectAll.Size = New-Object System.Drawing.Size(100, 30)
    $buttonDeselectAll.Text = 'Deselect All'
    $buttonDeselectAll.Enabled = $false
    $buttonDeselectAll.Name = 'buttonDeselectAll'
    $panel.Controls.Add($buttonDeselectAll)

    $labelSummary = New-Object System.Windows.Forms.Label
    $labelSummary.Location = New-Object System.Drawing.Point(320, 605)
    $labelSummary.Size = New-Object System.Drawing.Size(1040, 50)
    $labelSummary.Text = ''
    $labelSummary.Name = 'labelSummary'
    $panel.Controls.Add($labelSummary)

    return $panel
}

function Find-ControlByName {
    param(
        [System.Windows.Forms.Control]$Parent,
        [string]$Name
    )

    foreach ($control in $Parent.Controls) {
        if ($control.Name -eq $Name) {
            return $control
        }
        if ($control.Controls.Count -gt 0) {
            $found = Find-ControlByName -Parent $control -Name $Name
            if ($found) {
                return $found
            }
        }
    }
    return $null
}

Export-ModuleMember -Function New-MainForm, New-ConnectionPanel, New-MenuPanel, New-ServerManagementPanel, New-SnapshotManagementPanel, Find-ControlByName
