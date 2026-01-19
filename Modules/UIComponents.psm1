# UIComponents.psm1 - Modern UI component creation functions

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Modern color scheme
$script:ColorPrimary = [System.Drawing.Color]::FromArgb(41, 128, 185)      # Professional Blue
$script:ColorPrimaryDark = [System.Drawing.Color]::FromArgb(31, 97, 141)   # Darker Blue
$script:ColorAccent = [System.Drawing.Color]::FromArgb(52, 152, 219)       # Light Blue
$script:ColorSuccess = [System.Drawing.Color]::FromArgb(46, 204, 113)      # Green
$script:ColorWarning = [System.Drawing.Color]::FromArgb(241, 196, 15)      # Yellow
$script:ColorDanger = [System.Drawing.Color]::FromArgb(231, 76, 60)        # Red
$script:ColorBackground = [System.Drawing.Color]::FromArgb(236, 240, 241)  # Light Gray
$script:ColorPanel = [System.Drawing.Color]::White                         # White
$script:ColorText = [System.Drawing.Color]::FromArgb(44, 62, 80)           # Dark Gray
$script:ColorTextLight = [System.Drawing.Color]::FromArgb(127, 140, 141)   # Medium Gray
$script:ColorBorder = [System.Drawing.Color]::FromArgb(189, 195, 199)      # Border Gray

function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Hyper-V Server Management Tool'
    $form.Size = New-Object System.Drawing.Size(1500, 900)
    $form.StartPosition = 'CenterScreen'
    $form.MinimumSize = New-Object System.Drawing.Size(1400, 800)
    $form.BackColor = $script:ColorBackground
    $form.FormBorderStyle = 'None'  # Remove default title bar
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    return $form
}

function New-CustomTitleBar {
    param([System.Windows.Forms.Form]$Form)

    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size = New-Object System.Drawing.Size(1500, 40)
    $titleBar.BackColor = $script:ColorPrimaryDark
    $titleBar.Name = 'titleBar'

    # Title label with icon
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(15, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 20)
    $titleLabel.Text = 'Hyper-V Server Management Tool'
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleBar.Controls.Add($titleLabel)

    # Minimize button
    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Location = New-Object System.Drawing.Point(1380, 5)
    $btnMinimize.Size = New-Object System.Drawing.Size(30, 30)
    $btnMinimize.Text = '─'
    $btnMinimize.ForeColor = [System.Drawing.Color]::White
    $btnMinimize.BackColor = [System.Drawing.Color]::Transparent
    $btnMinimize.FlatStyle = 'Flat'
    $btnMinimize.FlatAppearance.BorderSize = 0
    $btnMinimize.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnMinimize.Add_Click({ $Form.WindowState = 'Minimized' })
    $btnMinimize.Add_MouseEnter({ $btnMinimize.BackColor = $script:ColorPrimary })
    $btnMinimize.Add_MouseLeave({ $btnMinimize.BackColor = [System.Drawing.Color]::Transparent })
    $titleBar.Controls.Add($btnMinimize)

    # Maximize button
    $btnMaximize = New-Object System.Windows.Forms.Button
    $btnMaximize.Location = New-Object System.Drawing.Point(1420, 5)
    $btnMaximize.Size = New-Object System.Drawing.Size(30, 30)
    $btnMaximize.Text = '▢'
    $btnMaximize.ForeColor = [System.Drawing.Color]::White
    $btnMaximize.BackColor = [System.Drawing.Color]::Transparent
    $btnMaximize.FlatStyle = 'Flat'
    $btnMaximize.FlatAppearance.BorderSize = 0
    $btnMaximize.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $btnMaximize.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnMaximize.Add_Click({
        if ($Form.WindowState -eq 'Maximized') {
            $Form.WindowState = 'Normal'
        } else {
            $Form.WindowState = 'Maximized'
        }
    })
    $btnMaximize.Add_MouseEnter({ $btnMaximize.BackColor = $script:ColorPrimary })
    $btnMaximize.Add_MouseLeave({ $btnMaximize.BackColor = [System.Drawing.Color]::Transparent })
    $titleBar.Controls.Add($btnMaximize)

    # Close button
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(1460, 5)
    $btnClose.Size = New-Object System.Drawing.Size(30, 30)
    $btnClose.Text = 'X'
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.BackColor = [System.Drawing.Color]::Transparent
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_Click({ $Form.Close() })
    $btnClose.Add_MouseEnter({ $btnClose.BackColor = $script:ColorDanger })
    $btnClose.Add_MouseLeave({ $btnClose.BackColor = [System.Drawing.Color]::Transparent })
    $titleBar.Controls.Add($btnClose)

    # Make title bar draggable
    $titleBar.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $Form.Tag = @{
                Dragging = $true
                StartPoint = $e.Location
            }
        }
    })

    $titleBar.Add_MouseMove({
        param($sender, $e)
        if ($Form.Tag -and $Form.Tag.Dragging) {
            $Form.Location = [System.Drawing.Point]::new(
                $Form.Location.X + ($e.X - $Form.Tag.StartPoint.X),
                $Form.Location.Y + ($e.Y - $Form.Tag.StartPoint.Y)
            )
        }
    })

    $titleBar.Add_MouseUp({
        param($sender, $e)
        if ($Form.Tag) {
            $Form.Tag.Dragging = $false
        }
    })

    return $titleBar
}

function New-ConnectionPanel {
    param([System.Windows.Forms.Form]$Form)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 40)
    $panel.Size = New-Object System.Drawing.Size(1500, 85)
    $panel.BackColor = $script:ColorPanel
    $panel.BorderStyle = 'None'

    # Add subtle shadow effect
    $shadowLabel = New-Object System.Windows.Forms.Label
    $shadowLabel.Location = New-Object System.Drawing.Point(0, 83)
    $shadowLabel.Size = New-Object System.Drawing.Size(1500, 2)
    $shadowLabel.BackColor = $script:ColorBorder
    $panel.Controls.Add($shadowLabel)

    # Labels and textbox
    $labelNodes = New-Object System.Windows.Forms.Label
    $labelNodes.Location = New-Object System.Drawing.Point(20, 20)
    $labelNodes.Size = New-Object System.Drawing.Size(120, 25)
    $labelNodes.Text = 'Hyper-V Nodes:'
    $labelNodes.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $labelNodes.ForeColor = $script:ColorText
    $panel.Controls.Add($labelNodes)

    $textBoxNodes = New-Object System.Windows.Forms.TextBox
    $textBoxNodes.Location = New-Object System.Drawing.Point(150, 18)
    $textBoxNodes.Size = New-Object System.Drawing.Size(400, 25)
    $textBoxNodes.Text = 'localhost'
    $textBoxNodes.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textBoxNodes.BorderStyle = 'FixedSingle'
    $textBoxNodes.Name = 'textBoxNodes'
    $panel.Controls.Add($textBoxNodes)

    $labelHelp = New-Object System.Windows.Forms.Label
    $labelHelp.Location = New-Object System.Drawing.Point(560, 20)
    $labelHelp.Size = New-Object System.Drawing.Size(250, 25)
    $labelHelp.Text = '(comma-separated for multiple)'
    $labelHelp.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $labelHelp.ForeColor = $script:ColorTextLight
    $panel.Controls.Add($labelHelp)

    # Modern styled buttons
    $buttonConnect = New-Object System.Windows.Forms.Button
    $buttonConnect.Location = New-Object System.Drawing.Point(1100, 15)
    $buttonConnect.Size = New-Object System.Drawing.Size(120, 35)
    $buttonConnect.Text = 'Connect'
    $buttonConnect.BackColor = $script:ColorPrimary
    $buttonConnect.ForeColor = [System.Drawing.Color]::White
    $buttonConnect.FlatStyle = 'Flat'
    $buttonConnect.FlatAppearance.BorderSize = 0
    $buttonConnect.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $buttonConnect.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonConnect.Name = 'buttonConnect'
    $buttonConnect.Add_MouseEnter({ $buttonConnect.BackColor = $script:ColorAccent })
    $buttonConnect.Add_MouseLeave({ $buttonConnect.BackColor = $script:ColorPrimary })
    $panel.Controls.Add($buttonConnect)

    $buttonBackToMenu = New-Object System.Windows.Forms.Button
    $buttonBackToMenu.Location = New-Object System.Drawing.Point(1230, 15)
    $buttonBackToMenu.Size = New-Object System.Drawing.Size(140, 35)
    $buttonBackToMenu.Text = '← Back to Menu'
    $buttonBackToMenu.BackColor = $script:ColorTextLight
    $buttonBackToMenu.ForeColor = [System.Drawing.Color]::White
    $buttonBackToMenu.FlatStyle = 'Flat'
    $buttonBackToMenu.FlatAppearance.BorderSize = 0
    $buttonBackToMenu.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $buttonBackToMenu.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonBackToMenu.Enabled = $false
    $buttonBackToMenu.Name = 'buttonBackToMenu'
    $buttonBackToMenu.Add_MouseEnter({ if ($buttonBackToMenu.Enabled) { $buttonBackToMenu.BackColor = $script:ColorText } })
    $buttonBackToMenu.Add_MouseLeave({ if ($buttonBackToMenu.Enabled) { $buttonBackToMenu.BackColor = $script:ColorTextLight } })
    $panel.Controls.Add($buttonBackToMenu)

    # Status label
    $labelStatus = New-Object System.Windows.Forms.Label
    $labelStatus.Location = New-Object System.Drawing.Point(20, 55)
    $labelStatus.Size = New-Object System.Drawing.Size(1350, 25)
    $labelStatus.Text = 'Enter Hyper-V node(s) and click Connect'
    $labelStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $labelStatus.ForeColor = $script:ColorPrimary
    $labelStatus.Name = 'labelStatus'
    $panel.Controls.Add($labelStatus)

    $panel.Name = 'panelConnection'
    return $panel
}

function New-MenuPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 125)
    $panel.Size = New-Object System.Drawing.Size(1500, 775)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $true
    $panel.Name = 'panelMenu'

    $labelWelcome = New-Object System.Windows.Forms.Label
    $labelWelcome.Location = New-Object System.Drawing.Point(450, 120)
    $labelWelcome.Size = New-Object System.Drawing.Size(600, 50)
    $labelWelcome.Text = 'Hyper-V Server Management'
    $labelWelcome.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $labelWelcome.TextAlign = 'MiddleCenter'
    $labelWelcome.ForeColor = $script:ColorText
    $panel.Controls.Add($labelWelcome)

    $labelSubtitle = New-Object System.Windows.Forms.Label
    $labelSubtitle.Location = New-Object System.Drawing.Point(450, 175)
    $labelSubtitle.Size = New-Object System.Drawing.Size(600, 30)
    $labelSubtitle.Text = 'Connect to a Hyper-V node to begin'
    $labelSubtitle.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $labelSubtitle.TextAlign = 'MiddleCenter'
    $labelSubtitle.ForeColor = $script:ColorTextLight
    $panel.Controls.Add($labelSubtitle)

    # Server Management Button - Modern card style
    $buttonServerMgmt = New-Object System.Windows.Forms.Button
    $buttonServerMgmt.Location = New-Object System.Drawing.Point(500, 280)
    $buttonServerMgmt.Size = New-Object System.Drawing.Size(500, 100)
    $buttonServerMgmt.Text = "Server Management`n`nView IP addresses, memory, storage, and CPU information"
    $buttonServerMgmt.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $buttonServerMgmt.BackColor = $script:ColorPanel
    $buttonServerMgmt.ForeColor = $script:ColorText
    $buttonServerMgmt.FlatStyle = 'Flat'
    $buttonServerMgmt.FlatAppearance.BorderColor = $script:ColorBorder
    $buttonServerMgmt.FlatAppearance.BorderSize = 2
    $buttonServerMgmt.Enabled = $false
    $buttonServerMgmt.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonServerMgmt.Name = 'buttonServerMgmt'
    $buttonServerMgmt.Add_MouseEnter({
        if ($buttonServerMgmt.Enabled) {
            $buttonServerMgmt.BackColor = $script:ColorAccent
            $buttonServerMgmt.ForeColor = [System.Drawing.Color]::White
        }
    })
    $buttonServerMgmt.Add_MouseLeave({
        if ($buttonServerMgmt.Enabled) {
            $buttonServerMgmt.BackColor = $script:ColorPanel
            $buttonServerMgmt.ForeColor = $script:ColorText
        }
    })
    $panel.Controls.Add($buttonServerMgmt)

    # Snapshot Management Button
    $buttonSnapshotMgmt = New-Object System.Windows.Forms.Button
    $buttonSnapshotMgmt.Location = New-Object System.Drawing.Point(500, 410)
    $buttonSnapshotMgmt.Size = New-Object System.Drawing.Size(500, 100)
    $buttonSnapshotMgmt.Text = "Snapshot Management`n`nView and manage VM snapshots"
    $buttonSnapshotMgmt.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $buttonSnapshotMgmt.BackColor = $script:ColorPanel
    $buttonSnapshotMgmt.ForeColor = $script:ColorText
    $buttonSnapshotMgmt.FlatStyle = 'Flat'
    $buttonSnapshotMgmt.FlatAppearance.BorderColor = $script:ColorBorder
    $buttonSnapshotMgmt.FlatAppearance.BorderSize = 2
    $buttonSnapshotMgmt.Enabled = $false
    $buttonSnapshotMgmt.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonSnapshotMgmt.Name = 'buttonSnapshotMgmt'
    $buttonSnapshotMgmt.Add_MouseEnter({
        if ($buttonSnapshotMgmt.Enabled) {
            $buttonSnapshotMgmt.BackColor = $script:ColorSuccess
            $buttonSnapshotMgmt.ForeColor = [System.Drawing.Color]::White
        }
    })
    $buttonSnapshotMgmt.Add_MouseLeave({
        if ($buttonSnapshotMgmt.Enabled) {
            $buttonSnapshotMgmt.BackColor = $script:ColorPanel
            $buttonSnapshotMgmt.ForeColor = $script:ColorText
        }
    })
    $panel.Controls.Add($buttonSnapshotMgmt)

    return $panel
}

function New-ServerManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 125)
    $panel.Size = New-Object System.Drawing.Size(1500, 775)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $false
    $panel.Name = 'panelServer'

    # Title and buttons bar
    $labelServerTitle = New-Object System.Windows.Forms.Label
    $labelServerTitle.Location = New-Object System.Drawing.Point(20, 15)
    $labelServerTitle.Size = New-Object System.Drawing.Size(250, 35)
    $labelServerTitle.Text = 'Server Management'
    $labelServerTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $labelServerTitle.ForeColor = $script:ColorText
    $panel.Controls.Add($labelServerTitle)

    # Search box
    $textBoxSearch = New-Object System.Windows.Forms.TextBox
    $textBoxSearch.Location = New-Object System.Drawing.Point(300, 18)
    $textBoxSearch.Size = New-Object System.Drawing.Size(300, 30)
    $textBoxSearch.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textBoxSearch.BorderStyle = 'FixedSingle'
    $textBoxSearch.Name = 'textBoxSearchServer'
    $textBoxSearch.Text = 'Search VMs...'
    $textBoxSearch.ForeColor = $script:ColorTextLight
    $panel.Controls.Add($textBoxSearch)

    # Filter by state dropdown
    $comboBoxFilter = New-Object System.Windows.Forms.ComboBox
    $comboBoxFilter.Location = New-Object System.Drawing.Point(610, 18)
    $comboBoxFilter.Size = New-Object System.Drawing.Size(150, 30)
    $comboBoxFilter.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $comboBoxFilter.DropDownStyle = 'DropDownList'
    $comboBoxFilter.Items.AddRange(@('All States', 'Running', 'Stopped', 'Paused', 'Saved'))
    $comboBoxFilter.SelectedIndex = 0
    $comboBoxFilter.Name = 'comboBoxFilterServer'
    $panel.Controls.Add($comboBoxFilter)

    # Show favorites only checkbox
    $checkBoxFavorites = New-Object System.Windows.Forms.CheckBox
    $checkBoxFavorites.Location = New-Object System.Drawing.Point(770, 20)
    $checkBoxFavorites.Size = New-Object System.Drawing.Size(150, 25)
    $checkBoxFavorites.Text = 'Favorites Only'
    $checkBoxFavorites.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $checkBoxFavorites.ForeColor = $script:ColorText
    $checkBoxFavorites.Name = 'checkBoxFavoritesServer'
    $panel.Controls.Add($checkBoxFavorites)

    # Export button
    $buttonExport = New-Object System.Windows.Forms.Button
    $buttonExport.Location = New-Object System.Drawing.Point(1140, 15)
    $buttonExport.Size = New-Object System.Drawing.Size(110, 35)
    $buttonExport.Text = 'Export CSV'
    $buttonExport.BackColor = $script:ColorSuccess
    $buttonExport.ForeColor = [System.Drawing.Color]::White
    $buttonExport.FlatStyle = 'Flat'
    $buttonExport.FlatAppearance.BorderSize = 0
    $buttonExport.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $buttonExport.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonExport.Name = 'buttonExportServer'
    $panel.Controls.Add($buttonExport)

    # Refresh button
    $buttonRefreshServer = New-Object System.Windows.Forms.Button
    $buttonRefreshServer.Location = New-Object System.Drawing.Point(1260, 15)
    $buttonRefreshServer.Size = New-Object System.Drawing.Size(110, 35)
    $buttonRefreshServer.Text = 'Refresh'
    $buttonRefreshServer.BackColor = $script:ColorPrimary
    $buttonRefreshServer.ForeColor = [System.Drawing.Color]::White
    $buttonRefreshServer.FlatStyle = 'Flat'
    $buttonRefreshServer.FlatAppearance.BorderSize = 0
    $buttonRefreshServer.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $buttonRefreshServer.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonRefreshServer.Name = 'buttonRefreshServer'
    $panel.Controls.Add($buttonRefreshServer)

    # DataGridView with modern styling
    $dataGridServer = New-Object System.Windows.Forms.DataGridView
    $dataGridServer.Location = New-Object System.Drawing.Point(20, 65)
    $dataGridServer.Size = New-Object System.Drawing.Size(1450, 650)
    $dataGridServer.AllowUserToAddRows = $false
    $dataGridServer.AllowUserToDeleteRows = $false
    $dataGridServer.ReadOnly = $true
    $dataGridServer.SelectionMode = 'FullRowSelect'
    $dataGridServer.MultiSelect = $false
    $dataGridServer.AutoSizeColumnsMode = 'Fill'
    $dataGridServer.BackgroundColor = $script:ColorPanel
    $dataGridServer.BorderStyle = 'None'
    $dataGridServer.GridColor = $script:ColorBorder
    $dataGridServer.RowHeadersVisible = $false
    $dataGridServer.EnableHeadersVisualStyles = $false
    $dataGridServer.ColumnHeadersDefaultCellStyle.BackColor = $script:ColorPrimary
    $dataGridServer.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridServer.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $dataGridServer.ColumnHeadersHeight = 35
    $dataGridServer.DefaultCellStyle.SelectionBackColor = $script:ColorAccent
    $dataGridServer.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridServer.AlternatingRowsDefaultCellStyle.BackColor = $script:ColorBackground
    $dataGridServer.Name = 'dataGridServer'
    $panel.Controls.Add($dataGridServer)

    # Summary label
    $labelSummaryServer = New-Object System.Windows.Forms.Label
    $labelSummaryServer.Location = New-Object System.Drawing.Point(20, 725)
    $labelSummaryServer.Size = New-Object System.Drawing.Size(1450, 30)
    $labelSummaryServer.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $labelSummaryServer.ForeColor = $script:ColorText
    $labelSummaryServer.Name = 'labelSummaryServer'
    $panel.Controls.Add($labelSummaryServer)

    return $panel
}

function New-SnapshotManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 125)
    $panel.Size = New-Object System.Drawing.Size(1500, 775)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $false
    $panel.Name = 'panelSnapshot'

    # Title
    $labelSnapshotTitle = New-Object System.Windows.Forms.Label
    $labelSnapshotTitle.Location = New-Object System.Drawing.Point(20, 15)
    $labelSnapshotTitle.Size = New-Object System.Drawing.Size(300, 35)
    $labelSnapshotTitle.Text = 'Snapshot Management'
    $labelSnapshotTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $labelSnapshotTitle.ForeColor = $script:ColorText
    $panel.Controls.Add($labelSnapshotTitle)

    # VMs section
    $labelVMs = New-Object System.Windows.Forms.Label
    $labelVMs.Location = New-Object System.Drawing.Point(20, 60)
    $labelVMs.Size = New-Object System.Drawing.Size(200, 25)
    $labelVMs.Text = 'Virtual Machines:'
    $labelVMs.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $labelVMs.ForeColor = $script:ColorText
    $panel.Controls.Add($labelVMs)

    # VM search box
    $textBoxSearchVM = New-Object System.Windows.Forms.TextBox
    $textBoxSearchVM.Location = New-Object System.Drawing.Point(20, 90)
    $textBoxSearchVM.Size = New-Object System.Drawing.Size(330, 30)
    $textBoxSearchVM.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $textBoxSearchVM.BorderStyle = 'FixedSingle'
    $textBoxSearchVM.Name = 'textBoxSearchVM'
    $textBoxSearchVM.Text = 'Search VMs...'
    $textBoxSearchVM.ForeColor = $script:ColorTextLight
    $panel.Controls.Add($textBoxSearchVM)

    $listBoxVMs = New-Object System.Windows.Forms.ListBox
    $listBoxVMs.Location = New-Object System.Drawing.Point(20, 125)
    $listBoxVMs.Size = New-Object System.Drawing.Size(330, 530)
    $listBoxVMs.SelectionMode = 'MultiExtended'
    $listBoxVMs.BackColor = $script:ColorPanel
    $listBoxVMs.BorderStyle = 'FixedSingle'
    $listBoxVMs.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $listBoxVMs.Name = 'listBoxVMs'
    $panel.Controls.Add($listBoxVMs)

    # Snapshots section
    $labelSnapshots = New-Object System.Windows.Forms.Label
    $labelSnapshots.Location = New-Object System.Drawing.Point(370, 60)
    $labelSnapshots.Size = New-Object System.Drawing.Size(200, 25)
    $labelSnapshots.Text = 'VM Snapshots:'
    $labelSnapshots.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $labelSnapshots.ForeColor = $script:ColorText
    $panel.Controls.Add($labelSnapshots)

    # Snapshot search
    $textBoxSearchSnapshot = New-Object System.Windows.Forms.TextBox
    $textBoxSearchSnapshot.Location = New-Object System.Drawing.Point(370, 90)
    $textBoxSearchSnapshot.Size = New-Object System.Drawing.Size(300, 30)
    $textBoxSearchSnapshot.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $textBoxSearchSnapshot.BorderStyle = 'FixedSingle'
    $textBoxSearchSnapshot.Name = 'textBoxSearchSnapshot'
    $textBoxSearchSnapshot.Text = 'Search snapshots...'
    $textBoxSearchSnapshot.ForeColor = $script:ColorTextLight
    $panel.Controls.Add($textBoxSearchSnapshot)

    # Filter older than dropdown
    $comboBoxAgeFilter = New-Object System.Windows.Forms.ComboBox
    $comboBoxAgeFilter.Location = New-Object System.Drawing.Point(680, 90)
    $comboBoxAgeFilter.Size = New-Object System.Drawing.Size(160, 30)
    $comboBoxAgeFilter.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $comboBoxAgeFilter.DropDownStyle = 'DropDownList'
    $comboBoxAgeFilter.Items.AddRange(@('All Ages', 'Older than 7 days', 'Older than 30 days', 'Older than 90 days'))
    $comboBoxAgeFilter.SelectedIndex = 0
    $comboBoxAgeFilter.Name = 'comboBoxAgeFilter'
    $panel.Controls.Add($comboBoxAgeFilter)

    # Export button
    $buttonExportSnapshot = New-Object System.Windows.Forms.Button
    $buttonExportSnapshot.Location = New-Object System.Drawing.Point(1020, 87)
    $buttonExportSnapshot.Size = New-Object System.Drawing.Size(110, 30)
    $buttonExportSnapshot.Text = 'Export CSV'
    $buttonExportSnapshot.BackColor = $script:ColorSuccess
    $buttonExportSnapshot.ForeColor = [System.Drawing.Color]::White
    $buttonExportSnapshot.FlatStyle = 'Flat'
    $buttonExportSnapshot.FlatAppearance.BorderSize = 0
    $buttonExportSnapshot.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $buttonExportSnapshot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonExportSnapshot.Name = 'buttonExportSnapshot'
    $panel.Controls.Add($buttonExportSnapshot)

    # Refresh button
    $buttonRefreshSnapshot = New-Object System.Windows.Forms.Button
    $buttonRefreshSnapshot.Location = New-Object System.Drawing.Point(1140, 87)
    $buttonRefreshSnapshot.Size = New-Object System.Drawing.Size(100, 30)
    $buttonRefreshSnapshot.Text = 'Refresh'
    $buttonRefreshSnapshot.BackColor = $script:ColorPrimary
    $buttonRefreshSnapshot.ForeColor = [System.Drawing.Color]::White
    $buttonRefreshSnapshot.FlatStyle = 'Flat'
    $buttonRefreshSnapshot.FlatAppearance.BorderSize = 0
    $buttonRefreshSnapshot.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $buttonRefreshSnapshot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonRefreshSnapshot.Name = 'buttonRefreshSnapshot'
    $panel.Controls.Add($buttonRefreshSnapshot)

    # DataGridView for snapshots
    $dataGridSnapshots = New-Object System.Windows.Forms.DataGridView
    $dataGridSnapshots.Location = New-Object System.Drawing.Point(370, 125)
    $dataGridSnapshots.Size = New-Object System.Drawing.Size(1100, 480)
    $dataGridSnapshots.AllowUserToAddRows = $false
    $dataGridSnapshots.AllowUserToDeleteRows = $false
    $dataGridSnapshots.ReadOnly = $true
    $dataGridSnapshots.SelectionMode = 'FullRowSelect'
    $dataGridSnapshots.MultiSelect = $true
    $dataGridSnapshots.AutoSizeColumnsMode = 'Fill'
    $dataGridSnapshots.BackgroundColor = $script:ColorPanel
    $dataGridSnapshots.BorderStyle = 'None'
    $dataGridSnapshots.GridColor = $script:ColorBorder
    $dataGridSnapshots.RowHeadersVisible = $false
    $dataGridSnapshots.EnableHeadersVisualStyles = $false
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.BackColor = $script:ColorPrimary
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $dataGridSnapshots.ColumnHeadersHeight = 35
    $dataGridSnapshots.DefaultCellStyle.SelectionBackColor = $script:ColorAccent
    $dataGridSnapshots.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridSnapshots.AlternatingRowsDefaultCellStyle.BackColor = $script:ColorBackground
    $dataGridSnapshots.Name = 'dataGridSnapshots'
    $panel.Controls.Add($dataGridSnapshots)

    # Action buttons
    $buttonDelete = New-Object System.Windows.Forms.Button
    $buttonDelete.Location = New-Object System.Drawing.Point(370, 615)
    $buttonDelete.Size = New-Object System.Drawing.Size(160, 40)
    $buttonDelete.Text = 'Delete Selected'
    $buttonDelete.Enabled = $false
    $buttonDelete.BackColor = $script:ColorDanger
    $buttonDelete.ForeColor = [System.Drawing.Color]::White
    $buttonDelete.FlatStyle = 'Flat'
    $buttonDelete.FlatAppearance.BorderSize = 0
    $buttonDelete.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $buttonDelete.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonDelete.Name = 'buttonDelete'
    $panel.Controls.Add($buttonDelete)

    $buttonSelectAll = New-Object System.Windows.Forms.Button
    $buttonSelectAll.Location = New-Object System.Drawing.Point(540, 615)
    $buttonSelectAll.Size = New-Object System.Drawing.Size(120, 40)
    $buttonSelectAll.Text = 'Select All'
    $buttonSelectAll.Enabled = $false
    $buttonSelectAll.BackColor = $script:ColorTextLight
    $buttonSelectAll.ForeColor = [System.Drawing.Color]::White
    $buttonSelectAll.FlatStyle = 'Flat'
    $buttonSelectAll.FlatAppearance.BorderSize = 0
    $buttonSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonSelectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonSelectAll.Name = 'buttonSelectAll'
    $panel.Controls.Add($buttonSelectAll)

    $buttonDeselectAll = New-Object System.Windows.Forms.Button
    $buttonDeselectAll.Location = New-Object System.Drawing.Point(670, 615)
    $buttonDeselectAll.Size = New-Object System.Drawing.Size(120, 40)
    $buttonDeselectAll.Text = 'Deselect All'
    $buttonDeselectAll.Enabled = $false
    $buttonDeselectAll.BackColor = $script:ColorTextLight
    $buttonDeselectAll.ForeColor = [System.Drawing.Color]::White
    $buttonDeselectAll.FlatStyle = 'Flat'
    $buttonDeselectAll.FlatAppearance.BorderSize = 0
    $buttonDeselectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonDeselectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonDeselectAll.Name = 'buttonDeselectAll'
    $panel.Controls.Add($buttonDeselectAll)

    # Summary label
    $labelSummary = New-Object System.Windows.Forms.Label
    $labelSummary.Location = New-Object System.Drawing.Point(370, 665)
    $labelSummary.Size = New-Object System.Drawing.Size(1100, 30)
    $labelSummary.Text = ''
    $labelSummary.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $labelSummary.ForeColor = $script:ColorText
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

Export-ModuleMember -Function New-MainForm, New-CustomTitleBar, New-ConnectionPanel, New-MenuPanel, New-ServerManagementPanel, New-SnapshotManagementPanel, Find-ControlByName
