# UIComponents.psm1 - Modern Dark Theme UI Components

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ═══════════════════════════════════════════════════════════════════════════════
# Modern Dark Theme - Color Palette
# ═══════════════════════════════════════════════════════════════════════════════
$script:ColorTitleBar       = [System.Drawing.Color]::FromArgb(15, 15, 22)       # Deepest dark - title bar
$script:ColorBackground     = [System.Drawing.Color]::FromArgb(22, 22, 30)       # Main background
$script:ColorSurface        = [System.Drawing.Color]::FromArgb(30, 32, 42)       # Cards, panels
$script:ColorSurfaceHover   = [System.Drawing.Color]::FromArgb(42, 44, 58)       # Elevated/hover
$script:ColorSurfaceBright  = [System.Drawing.Color]::FromArgb(52, 54, 70)       # Active elements
$script:ColorInputBg        = [System.Drawing.Color]::FromArgb(18, 18, 26)       # Input fields (inset)

$script:ColorPrimary        = [System.Drawing.Color]::FromArgb(99, 102, 241)     # Indigo accent
$script:ColorPrimaryHover   = [System.Drawing.Color]::FromArgb(129, 132, 255)    # Lighter indigo
$script:ColorPrimaryDark    = [System.Drawing.Color]::FromArgb(79, 82, 200)      # Darker indigo
$script:ColorAccent         = [System.Drawing.Color]::FromArgb(56, 189, 248)     # Sky blue
$script:ColorSuccess        = [System.Drawing.Color]::FromArgb(52, 211, 153)     # Emerald green
$script:ColorSuccessHover   = [System.Drawing.Color]::FromArgb(74, 232, 175)     # Lighter green
$script:ColorWarning        = [System.Drawing.Color]::FromArgb(251, 191, 36)     # Amber
$script:ColorDanger         = [System.Drawing.Color]::FromArgb(248, 113, 113)    # Soft red
$script:ColorDangerHover    = [System.Drawing.Color]::FromArgb(239, 68, 68)      # Brighter red

$script:ColorText           = [System.Drawing.Color]::FromArgb(237, 237, 245)    # Primary text
$script:ColorTextSecondary  = [System.Drawing.Color]::FromArgb(148, 163, 184)    # Secondary text
$script:ColorTextDim        = [System.Drawing.Color]::FromArgb(100, 116, 139)    # Dim text
$script:ColorBorder         = [System.Drawing.Color]::FromArgb(50, 52, 66)       # Subtle borders
$script:ColorBorderLight    = [System.Drawing.Color]::FromArgb(62, 64, 80)       # Lighter borders

$script:ColorGridHeader     = [System.Drawing.Color]::FromArgb(34, 36, 48)       # Grid header
$script:ColorGridAlt        = [System.Drawing.Color]::FromArgb(26, 27, 36)       # Alt row
$script:ColorSelection      = [System.Drawing.Color]::FromArgb(99, 102, 241)     # Selection (same as primary)
$script:ColorPanel          = [System.Drawing.Color]::FromArgb(30, 32, 42)       # Panel color (compatibility alias)

# ═══════════════════════════════════════════════════════════════════════════════
# Enable Double Buffering via reflection (reduces flicker)
# ═══════════════════════════════════════════════════════════════════════════════
function Enable-DoubleBuffering {
    param([System.Windows.Forms.Control]$Control)
    $prop = $Control.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
    if ($prop) { $prop.SetValue($Control, $true, $null) }
}

# ═══════════════════════════════════════════════════════════════════════════════
# Modern Custom Scrollbar - Creates a thin, modern-styled scrollbar overlay
# ═══════════════════════════════════════════════════════════════════════════════
$script:ScrollbarTrackColor = [System.Drawing.Color]::FromArgb(30, 32, 42)
$script:ScrollbarThumbColor = [System.Drawing.Color]::FromArgb(70, 72, 90)
$script:ScrollbarThumbHover = [System.Drawing.Color]::FromArgb(99, 102, 241)
$script:ScrollbarWidth = 8

function Add-ModernScrollbar {
    param(
        [System.Windows.Forms.DataGridView]$DataGrid,
        [System.Windows.Forms.Panel]$ParentPanel
    )

    # Create scrollbar track panel
    $scrollTrack = New-Object System.Windows.Forms.Panel
    $scrollTrack.Width = $script:ScrollbarWidth
    $scrollTrack.BackColor = $script:ScrollbarTrackColor
    $scrollTrack.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    # Position scrollbar at the right edge of the DataGrid
    $scrollTrack.Location = New-Object System.Drawing.Point(($DataGrid.Location.X + $DataGrid.Width - $script:ScrollbarWidth), $DataGrid.Location.Y)
    $scrollTrack.Height = $DataGrid.Height
    $scrollTrack.Name = 'modernScrollTrack'

    # Create scrollbar thumb
    $scrollThumb = New-Object System.Windows.Forms.Panel
    $scrollThumb.Width = $script:ScrollbarWidth - 2
    $scrollThumb.BackColor = $script:ScrollbarThumbColor
    $scrollThumb.Location = New-Object System.Drawing.Point(1, 0)
    $scrollThumb.Height = 50  # Initial height, will be calculated
    $scrollThumb.Name = 'modernScrollThumb'
    $scrollThumb.Cursor = [System.Windows.Forms.Cursors]::Hand

    # Round corners effect using region (approximate with smaller height adjustment)
    $scrollTrack.Controls.Add($scrollThumb)

    # Store references for event handlers
    $scrollThumb.Tag = @{
        DataGrid = $DataGrid
        Track = $scrollTrack
        IsDragging = $false
        DragStartY = 0
        DragStartScrollY = 0
    }

    # Thumb hover effect
    $scrollThumb.Add_MouseEnter({
        param($sender, $e)
        $sender.BackColor = $script:ScrollbarThumbHover
    })
    $scrollThumb.Add_MouseLeave({
        param($sender, $e)
        if (-not $sender.Tag.IsDragging) {
            $sender.BackColor = $script:ScrollbarThumbColor
        }
    })

    # Thumb drag functionality
    $scrollThumb.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $sender.Tag.IsDragging = $true
            $sender.Tag.DragStartY = $e.Y
            $sender.Tag.DragStartScrollY = $sender.Location.Y
            $sender.BackColor = $script:ScrollbarThumbHover
        }
    })

    $scrollThumb.Add_MouseMove({
        param($sender, $e)
        if ($sender.Tag.IsDragging) {
            $track = $sender.Tag.Track
            $grid = $sender.Tag.DataGrid

            # Calculate new thumb position
            $deltaY = $e.Y - $sender.Tag.DragStartY
            $newY = $sender.Tag.DragStartScrollY + $deltaY

            # Clamp to track bounds
            $maxY = $track.Height - $sender.Height
            $newY = [Math]::Max(0, [Math]::Min($newY, $maxY))

            $sender.Location = New-Object System.Drawing.Point($sender.Location.X, $newY)

            # Scroll the DataGrid
            if ($grid.RowCount -gt 0 -and $maxY -gt 0) {
                $scrollRatio = $newY / $maxY
                $targetRow = [Math]::Floor($scrollRatio * ($grid.RowCount - 1))
                $targetRow = [Math]::Max(0, [Math]::Min($targetRow, $grid.RowCount - 1))
                $grid.FirstDisplayedScrollingRowIndex = $targetRow
            }
        }
    })

    $scrollThumb.Add_MouseUp({
        param($sender, $e)
        $sender.Tag.IsDragging = $false
        $sender.BackColor = $script:ScrollbarThumbColor
    })

    # Track click to jump
    $scrollTrack.Add_MouseClick({
        param($sender, $e)
        $thumb = $sender.Controls['modernScrollThumb']
        $grid = $thumb.Tag.DataGrid

        if ($grid.RowCount -gt 0) {
            $clickRatio = $e.Y / $sender.Height
            $targetRow = [Math]::Floor($clickRatio * ($grid.RowCount - 1))
            $targetRow = [Math]::Max(0, [Math]::Min($targetRow, $grid.RowCount - 1))
            $grid.FirstDisplayedScrollingRowIndex = $targetRow
        }
    })

    # Update thumb position and size when grid scrolls or resizes
    $updateScrollbar = {
        param($grid, $thumb, $track)

        if ($grid.RowCount -eq 0) {
            $thumb.Visible = $false
            return
        }

        $visibleRows = [Math]::Max(1, $grid.DisplayedRowCount($true))
        $totalRows = $grid.RowCount

        if ($totalRows -le $visibleRows) {
            $thumb.Visible = $false
            return
        }

        $thumb.Visible = $true

        # Calculate thumb height
        $thumbHeight = [Math]::Max(30, [Math]::Floor(($visibleRows / $totalRows) * $track.Height))
        $thumb.Height = $thumbHeight

        # Calculate thumb position
        $scrollableRows = $totalRows - $visibleRows
        $currentRow = $grid.FirstDisplayedScrollingRowIndex
        $scrollRatio = if ($scrollableRows -gt 0) { $currentRow / $scrollableRows } else { 0 }
        $maxThumbY = $track.Height - $thumbHeight
        $thumbY = [Math]::Floor($scrollRatio * $maxThumbY)

        $thumb.Location = New-Object System.Drawing.Point(1, $thumbY)
    }.GetNewClosure()

    # Hook into DataGrid scroll event
    $DataGrid.Add_Scroll({
        param($sender, $e)
        $track = $sender.Parent.Controls['modernScrollTrack']
        if ($track) {
            $thumb = $track.Controls['modernScrollThumb']
            if ($thumb -and $thumb.Tag) {
                & $updateScrollbar $sender $thumb $track
            }
        }
    })

    # Hook into DataGrid DataSourceChanged to update scrollbar
    $DataGrid.Add_DataSourceChanged({
        param($sender, $e)
        $track = $sender.Parent.Controls['modernScrollTrack']
        if ($track) {
            $thumb = $track.Controls['modernScrollThumb']
            if ($thumb -and $thumb.Tag) {
                & $updateScrollbar $sender $thumb $track
            }
        }
    })

    # Initial update timer (for when data loads)
    $initTimer = New-Object System.Windows.Forms.Timer
    $initTimer.Interval = 100
    $initTimer.Add_Tick({
        param($sender, $e)
        $sender.Stop()
        $track = $DataGrid.Parent.Controls['modernScrollTrack']
        if ($track) {
            $thumb = $track.Controls['modernScrollThumb']
            if ($thumb -and $thumb.Tag) {
                & $updateScrollbar $DataGrid $thumb $track
            }
        }
        $sender.Dispose()
    }.GetNewClosure())
    $initTimer.Start()

    # Hide native scrollbar by adjusting grid width
    $DataGrid.ScrollBars = [System.Windows.Forms.ScrollBars]::None

    $ParentPanel.Controls.Add($scrollTrack)
    $scrollTrack.BringToFront()

    return $scrollTrack
}

function Add-ModernListBoxScrollbar {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        [System.Windows.Forms.Panel]$ParentPanel
    )

    # Create scrollbar track panel
    $scrollTrack = New-Object System.Windows.Forms.Panel
    $scrollTrack.Width = $script:ScrollbarWidth
    $scrollTrack.BackColor = $script:ScrollbarTrackColor
    $scrollTrack.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    # Position scrollbar at the right edge of the ListBox
    $scrollTrack.Location = New-Object System.Drawing.Point(($ListBox.Location.X + $ListBox.Width - $script:ScrollbarWidth), $ListBox.Location.Y)
    $scrollTrack.Height = $ListBox.Height
    $scrollTrack.Name = 'modernListScrollTrack'

    # Create scrollbar thumb
    $scrollThumb = New-Object System.Windows.Forms.Panel
    $scrollThumb.Width = $script:ScrollbarWidth - 2
    $scrollThumb.BackColor = $script:ScrollbarThumbColor
    $scrollThumb.Location = New-Object System.Drawing.Point(1, 0)
    $scrollThumb.Height = 50
    $scrollThumb.Name = 'modernListScrollThumb'
    $scrollThumb.Cursor = [System.Windows.Forms.Cursors]::Hand

    $scrollTrack.Controls.Add($scrollThumb)

    # Store references
    $scrollThumb.Tag = @{
        ListBox = $ListBox
        Track = $scrollTrack
        IsDragging = $false
        DragStartY = 0
        DragStartScrollY = 0
    }

    # Thumb hover effect
    $scrollThumb.Add_MouseEnter({
        param($sender, $e)
        $sender.BackColor = $script:ScrollbarThumbHover
    })
    $scrollThumb.Add_MouseLeave({
        param($sender, $e)
        if (-not $sender.Tag.IsDragging) {
            $sender.BackColor = $script:ScrollbarThumbColor
        }
    })

    # Thumb drag
    $scrollThumb.Add_MouseDown({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $sender.Tag.IsDragging = $true
            $sender.Tag.DragStartY = $e.Y
            $sender.Tag.DragStartScrollY = $sender.Location.Y
            $sender.BackColor = $script:ScrollbarThumbHover
        }
    })

    $scrollThumb.Add_MouseMove({
        param($sender, $e)
        if ($sender.Tag.IsDragging) {
            $track = $sender.Tag.Track
            $listBox = $sender.Tag.ListBox

            $deltaY = $e.Y - $sender.Tag.DragStartY
            $newY = $sender.Tag.DragStartScrollY + $deltaY

            $maxY = $track.Height - $sender.Height
            $newY = [Math]::Max(0, [Math]::Min($newY, $maxY))

            $sender.Location = New-Object System.Drawing.Point($sender.Location.X, $newY)

            if ($listBox.Items.Count -gt 0 -and $maxY -gt 0) {
                $scrollRatio = $newY / $maxY
                $targetIndex = [Math]::Floor($scrollRatio * ($listBox.Items.Count - 1))
                $targetIndex = [Math]::Max(0, [Math]::Min($targetIndex, $listBox.Items.Count - 1))
                $listBox.TopIndex = $targetIndex
            }
        }
    })

    $scrollThumb.Add_MouseUp({
        param($sender, $e)
        $sender.Tag.IsDragging = $false
        $sender.BackColor = $script:ScrollbarThumbColor
    })

    # Hide native scrollbar
    $ListBox.HorizontalScrollbar = $false

    $ParentPanel.Controls.Add($scrollTrack)
    $scrollTrack.BringToFront()

    return $scrollTrack
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Form
# ═══════════════════════════════════════════════════════════════════════════════
function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Hyper-V Server Management Tool'
    $form.Size = New-Object System.Drawing.Size(1500, 900)
    $form.StartPosition = 'CenterScreen'
    $form.MinimumSize = New-Object System.Drawing.Size(1400, 800)
    $form.BackColor = $script:ColorBackground
    $form.FormBorderStyle = 'None'
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    Enable-DoubleBuffering -Control $form

    return $form
}

# ═══════════════════════════════════════════════════════════════════════════════
# Custom Title Bar (Windows 11-style)
# ═══════════════════════════════════════════════════════════════════════════════
function New-CustomTitleBar {
    param([System.Windows.Forms.Form]$Form)

    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Location = New-Object System.Drawing.Point(0, 0)
    $titleBar.Size = New-Object System.Drawing.Size(1500, 36)
    $titleBar.BackColor = $script:ColorTitleBar
    $titleBar.Name = 'titleBar'

    # App icon indicator (small accent bar)
    $iconBar = New-Object System.Windows.Forms.Panel
    $iconBar.Location = New-Object System.Drawing.Point(0, 0)
    $iconBar.Size = New-Object System.Drawing.Size(3, 36)
    $iconBar.BackColor = $script:ColorPrimary
    $titleBar.Controls.Add($iconBar)

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(16, 0)
    $titleLabel.Size = New-Object System.Drawing.Size(500, 36)
    $titleLabel.Text = 'Hyper-V Server Management'
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 210)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $titleBar.Controls.Add($titleLabel)

    # --- Window Control Buttons (Windows 11 style) ---
    # Button dimensions: 46x36 (standard Windows 11 proportions)
    $btnWidth = 46
    $btnHeight = 36

    # Minimize Button
    $btnMinimize = New-Object System.Windows.Forms.Button
    $btnMinimize.Location = New-Object System.Drawing.Point((1500 - ($btnWidth * 3)), 0)
    $btnMinimize.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnMinimize.FlatStyle = 'Flat'
    $btnMinimize.FlatAppearance.BorderSize = 0
    $btnMinimize.FlatAppearance.MouseOverBackColor = $script:ColorSurfaceHover
    $btnMinimize.FlatAppearance.MouseDownBackColor = $script:ColorSurfaceBright
    $btnMinimize.BackColor = $script:ColorTitleBar
    $btnMinimize.Text = ''
    $btnMinimize.TabStop = $false
    $btnMinimize.Tag = 'minimize'
    $btnMinimize.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnMinimize.Add_Click({ param($s, $e); $s.FindForm().WindowState = 'Minimized' })
    $btnMinimize.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 180, 190), 1)
        $cx = [int]($sender.Width / 2)
        $cy = [int]($sender.Height / 2)
        $g.DrawLine($pen, ($cx - 5), $cy, ($cx + 5), $cy)
        $pen.Dispose()
    })
    $titleBar.Controls.Add($btnMinimize)

    # Maximize Button
    $btnMaximize = New-Object System.Windows.Forms.Button
    $btnMaximize.Location = New-Object System.Drawing.Point((1500 - ($btnWidth * 2)), 0)
    $btnMaximize.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnMaximize.FlatStyle = 'Flat'
    $btnMaximize.FlatAppearance.BorderSize = 0
    $btnMaximize.FlatAppearance.MouseOverBackColor = $script:ColorSurfaceHover
    $btnMaximize.FlatAppearance.MouseDownBackColor = $script:ColorSurfaceBright
    $btnMaximize.BackColor = $script:ColorTitleBar
    $btnMaximize.Text = ''
    $btnMaximize.TabStop = $false
    $btnMaximize.Tag = 'maximize'
    $btnMaximize.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnMaximize.Add_Click({
        param($s, $e)
        $f = $s.FindForm()
        if ($f.WindowState -eq 'Maximized') {
            $f.WindowState = 'Normal'
        } else {
            $f.WindowState = 'Maximized'
        }
    })
    $btnMaximize.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 180, 190), 1)
        $cx = [int]($sender.Width / 2)
        $cy = [int]($sender.Height / 2)
        $g.DrawRectangle($pen, ($cx - 5), ($cy - 5), 10, 10)
        $pen.Dispose()
    })
    $titleBar.Controls.Add($btnMaximize)

    # Close Button
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point((1500 - $btnWidth), 0)
    $btnClose.Size = New-Object System.Drawing.Size($btnWidth, $btnHeight)
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.FlatAppearance.MouseOverBackColor = $script:ColorDangerHover
    $btnClose.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(200, 40, 40)
    $btnClose.BackColor = $script:ColorTitleBar
    $btnClose.Text = ''
    $btnClose.TabStop = $false
    $btnClose.Tag = @{ IconType = 'close'; IsHovered = $false }
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnClose.Add_Click({ param($s, $e); $s.FindForm().Close() })
    $btnClose.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $iconColor = if ($sender.Tag.IsHovered) {
            [System.Drawing.Color]::White
        } else {
            [System.Drawing.Color]::FromArgb(180, 180, 190)
        }
        $pen = New-Object System.Drawing.Pen($iconColor, 1.2)
        $cx = [int]($sender.Width / 2)
        $cy = [int]($sender.Height / 2)
        $g.DrawLine($pen, ($cx - 5), ($cy - 5), ($cx + 5), ($cy + 5))
        $g.DrawLine($pen, ($cx + 5), ($cy - 5), ($cx - 5), ($cy + 5))
        $pen.Dispose()
    })
    $btnClose.Add_MouseEnter({
        param($sender, $e)
        $sender.Tag = @{ IconType = 'close'; IsHovered = $true }
        $sender.Invalidate()
    })
    $btnClose.Add_MouseLeave({
        param($sender, $e)
        $sender.Tag = @{ IconType = 'close'; IsHovered = $false }
        $sender.Invalidate()
    })
    $titleBar.Controls.Add($btnClose)

    # Accent line at the bottom of the title bar
    $accentLine = New-Object System.Windows.Forms.Panel
    $accentLine.Location = New-Object System.Drawing.Point(0, 35)
    $accentLine.Size = New-Object System.Drawing.Size(1500, 1)
    $accentLine.BackColor = $script:ColorBorder
    $titleBar.Controls.Add($accentLine)

    # --- Make title bar draggable (both panel and label) ---
    $dragHandler_MouseDown = {
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $parentForm = $sender.FindForm()
            $parentForm.Tag = @{
                Dragging = $true
                StartPoint = $e.Location
            }
        }
    }
    $dragHandler_MouseMove = {
        param($sender, $e)
        $parentForm = $sender.FindForm()
        if ($parentForm.Tag -and $parentForm.Tag.Dragging) {
            $parentForm.Location = [System.Drawing.Point]::new(
                $parentForm.Location.X + ($e.X - $parentForm.Tag.StartPoint.X),
                $parentForm.Location.Y + ($e.Y - $parentForm.Tag.StartPoint.Y)
            )
        }
    }
    $dragHandler_MouseUp = {
        param($sender, $e)
        $parentForm = $sender.FindForm()
        if ($parentForm.Tag) { $parentForm.Tag.Dragging = $false }
    }

    # Attach drag to both panel and title label
    $titleBar.Add_MouseDown($dragHandler_MouseDown)
    $titleBar.Add_MouseMove($dragHandler_MouseMove)
    $titleBar.Add_MouseUp($dragHandler_MouseUp)
    $titleLabel.Add_MouseDown($dragHandler_MouseDown)
    $titleLabel.Add_MouseMove($dragHandler_MouseMove)
    $titleLabel.Add_MouseUp($dragHandler_MouseUp)

    return $titleBar
}

# ═══════════════════════════════════════════════════════════════════════════════
# Connection Panel (toolbar area below title bar)
# ═══════════════════════════════════════════════════════════════════════════════
function New-ConnectionPanel {
    param([System.Windows.Forms.Form]$Form)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 36)
    $panel.Size = New-Object System.Drawing.Size(1500, 70)
    $panel.BackColor = $script:ColorSurface
    $panel.BorderStyle = 'None'

    # Bottom border
    $borderLine = New-Object System.Windows.Forms.Panel
    $borderLine.Location = New-Object System.Drawing.Point(0, 69)
    $borderLine.Size = New-Object System.Drawing.Size(1500, 1)
    $borderLine.BackColor = $script:ColorBorder
    $panel.Controls.Add($borderLine)

    # Node label
    $labelNodes = New-Object System.Windows.Forms.Label
    $labelNodes.Location = New-Object System.Drawing.Point(20, 14)
    $labelNodes.Size = New-Object System.Drawing.Size(105, 20)
    $labelNodes.Text = 'Hyper-V Nodes'
    $labelNodes.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $labelNodes.ForeColor = $script:ColorTextSecondary
    $panel.Controls.Add($labelNodes)

    # Node textbox
    $textBoxNodes = New-Object System.Windows.Forms.TextBox
    $textBoxNodes.Location = New-Object System.Drawing.Point(130, 11)
    $textBoxNodes.Size = New-Object System.Drawing.Size(420, 28)
    $textBoxNodes.Text = 'localhost'
    $textBoxNodes.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $textBoxNodes.BorderStyle = 'FixedSingle'
    $textBoxNodes.BackColor = $script:ColorInputBg
    $textBoxNodes.ForeColor = $script:ColorText
    $textBoxNodes.Name = 'textBoxNodes'
    $panel.Controls.Add($textBoxNodes)

    # Help text
    $labelHelp = New-Object System.Windows.Forms.Label
    $labelHelp.Location = New-Object System.Drawing.Point(560, 14)
    $labelHelp.Size = New-Object System.Drawing.Size(220, 20)
    $labelHelp.Text = 'comma-separated for multiple'
    $labelHelp.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $labelHelp.ForeColor = $script:ColorTextDim
    $panel.Controls.Add($labelHelp)

    # Connect button (primary style)
    $buttonConnect = New-Object System.Windows.Forms.Button
    $buttonConnect.Location = New-Object System.Drawing.Point(1100, 8)
    $buttonConnect.Size = New-Object System.Drawing.Size(120, 34)
    $buttonConnect.Text = 'Connect'
    $buttonConnect.BackColor = $script:ColorPrimary
    $buttonConnect.ForeColor = [System.Drawing.Color]::White
    $buttonConnect.FlatStyle = 'Flat'
    $buttonConnect.FlatAppearance.BorderSize = 0
    $buttonConnect.FlatAppearance.MouseOverBackColor = $script:ColorPrimaryHover
    $buttonConnect.FlatAppearance.MouseDownBackColor = $script:ColorPrimaryDark
    $buttonConnect.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $buttonConnect.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonConnect.Name = 'buttonConnect'
    $panel.Controls.Add($buttonConnect)

    # Back to Menu button (subtle style)
    $buttonBackToMenu = New-Object System.Windows.Forms.Button
    $buttonBackToMenu.Location = New-Object System.Drawing.Point(1230, 8)
    $buttonBackToMenu.Size = New-Object System.Drawing.Size(140, 34)
    $buttonBackToMenu.Text = 'Back to Menu'
    $buttonBackToMenu.BackColor = $script:ColorSurfaceHover
    $buttonBackToMenu.ForeColor = $script:ColorTextSecondary
    $buttonBackToMenu.FlatStyle = 'Flat'
    $buttonBackToMenu.FlatAppearance.BorderSize = 0
    $buttonBackToMenu.FlatAppearance.MouseOverBackColor = $script:ColorSurfaceBright
    $buttonBackToMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $buttonBackToMenu.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonBackToMenu.Enabled = $false
    $buttonBackToMenu.Name = 'buttonBackToMenu'
    $panel.Controls.Add($buttonBackToMenu)

    # Status label
    $labelStatus = New-Object System.Windows.Forms.Label
    $labelStatus.Location = New-Object System.Drawing.Point(20, 46)
    $labelStatus.Size = New-Object System.Drawing.Size(1350, 20)
    $labelStatus.Text = 'Enter Hyper-V node(s) and click Connect'
    $labelStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $labelStatus.ForeColor = $script:ColorTextDim
    $labelStatus.Name = 'labelStatus'
    $panel.Controls.Add($labelStatus)

    $panel.Name = 'panelConnection'
    return $panel
}

# ═══════════════════════════════════════════════════════════════════════════════
# Menu Panel (landing page with feature cards)
# ═══════════════════════════════════════════════════════════════════════════════
function New-MenuPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 106)
    $panel.Size = New-Object System.Drawing.Size(1500, 794)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $true
    $panel.Name = 'panelMenu'

    # Welcome title
    $labelWelcome = New-Object System.Windows.Forms.Label
    $labelWelcome.Location = New-Object System.Drawing.Point(350, 100)
    $labelWelcome.Size = New-Object System.Drawing.Size(800, 50)
    $labelWelcome.Text = 'Hyper-V Server Management'
    $labelWelcome.Font = New-Object System.Drawing.Font("Segoe UI Light", 28)
    $labelWelcome.TextAlign = 'MiddleCenter'
    $labelWelcome.ForeColor = $script:ColorText
    $panel.Controls.Add($labelWelcome)

    # Subtitle
    $labelSubtitle = New-Object System.Windows.Forms.Label
    $labelSubtitle.Location = New-Object System.Drawing.Point(350, 158)
    $labelSubtitle.Size = New-Object System.Drawing.Size(800, 30)
    $labelSubtitle.Text = 'Connect to a Hyper-V node to get started'
    $labelSubtitle.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $labelSubtitle.TextAlign = 'MiddleCenter'
    $labelSubtitle.ForeColor = $script:ColorTextDim
    $panel.Controls.Add($labelSubtitle)

    # ── Server Management Card ──
    $cardServer = New-Object System.Windows.Forms.Panel
    $cardServer.Location = New-Object System.Drawing.Point(400, 240)
    $cardServer.Size = New-Object System.Drawing.Size(700, 110)
    $cardServer.BackColor = $script:ColorSurface
    $cardServer.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardServer.Name = 'panelCardServer'

    # Left accent strip
    $accentServer = New-Object System.Windows.Forms.Panel
    $accentServer.Location = New-Object System.Drawing.Point(0, 0)
    $accentServer.Size = New-Object System.Drawing.Size(4, 110)
    $accentServer.BackColor = $script:ColorPrimary
    $cardServer.Controls.Add($accentServer)

    # Card title
    $lblServerTitle = New-Object System.Windows.Forms.Label
    $lblServerTitle.Location = New-Object System.Drawing.Point(24, 20)
    $lblServerTitle.Size = New-Object System.Drawing.Size(650, 30)
    $lblServerTitle.Text = 'Server Management'
    $lblServerTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14)
    $lblServerTitle.ForeColor = $script:ColorText
    $lblServerTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblServerTitle.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardServer.Controls.Add($lblServerTitle)

    # Card description
    $lblServerDesc = New-Object System.Windows.Forms.Label
    $lblServerDesc.Location = New-Object System.Drawing.Point(24, 56)
    $lblServerDesc.Size = New-Object System.Drawing.Size(650, 30)
    $lblServerDesc.Text = 'View IP addresses, memory, storage, and CPU information for your VMs'
    $lblServerDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $lblServerDesc.ForeColor = $script:ColorTextSecondary
    $lblServerDesc.BackColor = [System.Drawing.Color]::Transparent
    $lblServerDesc.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardServer.Controls.Add($lblServerDesc)

    $panel.Controls.Add($cardServer)

    # Server card hover/click behavior (delegate to button)
    $buttonServerMgmt = New-Object System.Windows.Forms.Button
    $buttonServerMgmt.Location = New-Object System.Drawing.Point(0, 0)
    $buttonServerMgmt.Size = New-Object System.Drawing.Size(0, 0)
    $buttonServerMgmt.Enabled = $false
    $buttonServerMgmt.Name = 'buttonServerMgmt'
    $panel.Controls.Add($buttonServerMgmt)

    # Capture colors into local variables for closures
    $hoverColor = $script:ColorSurfaceHover
    $normalColor = $script:ColorSurface

    # Wire card click to hidden button (use GetNewClosure to capture local variables)
    $serverCardClick = {
        if ($buttonServerMgmt.Enabled) { $buttonServerMgmt.PerformClick() }
    }.GetNewClosure()
    $serverCardEnter = {
        if ($buttonServerMgmt.Enabled) {
            $cardServer.BackColor = $hoverColor
        }
    }.GetNewClosure()
    $serverCardLeave = {
        if ($buttonServerMgmt.Enabled) {
            $cardServer.BackColor = $normalColor
        }
    }.GetNewClosure()
    $cardServer.Add_Click($serverCardClick)
    $cardServer.Add_MouseEnter($serverCardEnter)
    $cardServer.Add_MouseLeave($serverCardLeave)
    $lblServerTitle.Add_Click($serverCardClick)
    $lblServerTitle.Add_MouseEnter($serverCardEnter)
    $lblServerTitle.Add_MouseLeave($serverCardLeave)
    $lblServerDesc.Add_Click($serverCardClick)
    $lblServerDesc.Add_MouseEnter($serverCardEnter)
    $lblServerDesc.Add_MouseLeave($serverCardLeave)

    # ── Snapshot Management Card ──
    $cardSnapshot = New-Object System.Windows.Forms.Panel
    $cardSnapshot.Location = New-Object System.Drawing.Point(400, 370)
    $cardSnapshot.Size = New-Object System.Drawing.Size(700, 110)
    $cardSnapshot.BackColor = $script:ColorSurface
    $cardSnapshot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardSnapshot.Name = 'panelCardSnapshot'

    # Left accent strip
    $accentSnapshot = New-Object System.Windows.Forms.Panel
    $accentSnapshot.Location = New-Object System.Drawing.Point(0, 0)
    $accentSnapshot.Size = New-Object System.Drawing.Size(4, 110)
    $accentSnapshot.BackColor = $script:ColorSuccess
    $cardSnapshot.Controls.Add($accentSnapshot)

    # Card title
    $lblSnapshotTitle = New-Object System.Windows.Forms.Label
    $lblSnapshotTitle.Location = New-Object System.Drawing.Point(24, 20)
    $lblSnapshotTitle.Size = New-Object System.Drawing.Size(650, 30)
    $lblSnapshotTitle.Text = 'Snapshot Management'
    $lblSnapshotTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14)
    $lblSnapshotTitle.ForeColor = $script:ColorText
    $lblSnapshotTitle.BackColor = [System.Drawing.Color]::Transparent
    $lblSnapshotTitle.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardSnapshot.Controls.Add($lblSnapshotTitle)

    # Card description
    $lblSnapshotDesc = New-Object System.Windows.Forms.Label
    $lblSnapshotDesc.Location = New-Object System.Drawing.Point(24, 56)
    $lblSnapshotDesc.Size = New-Object System.Drawing.Size(650, 30)
    $lblSnapshotDesc.Text = 'View, search, filter, and manage VM snapshots across your nodes'
    $lblSnapshotDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $lblSnapshotDesc.ForeColor = $script:ColorTextSecondary
    $lblSnapshotDesc.BackColor = [System.Drawing.Color]::Transparent
    $lblSnapshotDesc.Cursor = [System.Windows.Forms.Cursors]::Hand
    $cardSnapshot.Controls.Add($lblSnapshotDesc)

    $panel.Controls.Add($cardSnapshot)

    # Snapshot card hidden button
    $buttonSnapshotMgmt = New-Object System.Windows.Forms.Button
    $buttonSnapshotMgmt.Location = New-Object System.Drawing.Point(0, 0)
    $buttonSnapshotMgmt.Size = New-Object System.Drawing.Size(0, 0)
    $buttonSnapshotMgmt.Enabled = $false
    $buttonSnapshotMgmt.Name = 'buttonSnapshotMgmt'
    $panel.Controls.Add($buttonSnapshotMgmt)

    # Wire card click to hidden button (use GetNewClosure to capture local variables)
    $snapshotCardClick = {
        if ($buttonSnapshotMgmt.Enabled) { $buttonSnapshotMgmt.PerformClick() }
    }.GetNewClosure()
    $snapshotCardEnter = {
        if ($buttonSnapshotMgmt.Enabled) {
            $cardSnapshot.BackColor = $hoverColor
        }
    }.GetNewClosure()
    $snapshotCardLeave = {
        if ($buttonSnapshotMgmt.Enabled) {
            $cardSnapshot.BackColor = $normalColor
        }
    }.GetNewClosure()
    $cardSnapshot.Add_Click($snapshotCardClick)
    $cardSnapshot.Add_MouseEnter($snapshotCardEnter)
    $cardSnapshot.Add_MouseLeave($snapshotCardLeave)
    $lblSnapshotTitle.Add_Click($snapshotCardClick)
    $lblSnapshotTitle.Add_MouseEnter($snapshotCardEnter)
    $lblSnapshotTitle.Add_MouseLeave($snapshotCardLeave)
    $lblSnapshotDesc.Add_Click($snapshotCardClick)
    $lblSnapshotDesc.Add_MouseEnter($snapshotCardEnter)
    $lblSnapshotDesc.Add_MouseLeave($snapshotCardLeave)

    # Version/footer text
    $labelVersion = New-Object System.Windows.Forms.Label
    $labelVersion.Location = New-Object System.Drawing.Point(350, 520)
    $labelVersion.Size = New-Object System.Drawing.Size(800, 20)
    $labelVersion.Text = 'v3.0 - Modern UI'
    $labelVersion.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $labelVersion.TextAlign = 'MiddleCenter'
    $labelVersion.ForeColor = $script:ColorTextDim
    $panel.Controls.Add($labelVersion)

    return $panel
}

# ═══════════════════════════════════════════════════════════════════════════════
# Server Management Panel
# ═══════════════════════════════════════════════════════════════════════════════
function New-ServerManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 106)
    $panel.Size = New-Object System.Drawing.Size(1500, 794)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $false
    $panel.Name = 'panelServer'

    # ── Toolbar area ──
    $toolbar = New-Object System.Windows.Forms.Panel
    $toolbar.Location = New-Object System.Drawing.Point(0, 0)
    $toolbar.Size = New-Object System.Drawing.Size(1500, 56)
    $toolbar.BackColor = $script:ColorSurface
    $panel.Controls.Add($toolbar)

    # Bottom border
    $toolbarBorder = New-Object System.Windows.Forms.Panel
    $toolbarBorder.Location = New-Object System.Drawing.Point(0, 55)
    $toolbarBorder.Size = New-Object System.Drawing.Size(1500, 1)
    $toolbarBorder.BackColor = $script:ColorBorder
    $toolbar.Controls.Add($toolbarBorder)

    # Section title
    $labelServerTitle = New-Object System.Windows.Forms.Label
    $labelServerTitle.Location = New-Object System.Drawing.Point(20, 0)
    $labelServerTitle.Size = New-Object System.Drawing.Size(200, 55)
    $labelServerTitle.Text = 'Server Management'
    $labelServerTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 13)
    $labelServerTitle.ForeColor = $script:ColorText
    $labelServerTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $toolbar.Controls.Add($labelServerTitle)

    # Search box
    $textBoxSearch = New-Object System.Windows.Forms.TextBox
    $textBoxSearch.Location = New-Object System.Drawing.Point(240, 14)
    $textBoxSearch.Size = New-Object System.Drawing.Size(280, 28)
    $textBoxSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $textBoxSearch.BorderStyle = 'FixedSingle'
    $textBoxSearch.BackColor = $script:ColorInputBg
    $textBoxSearch.ForeColor = $script:ColorTextDim
    $textBoxSearch.Name = 'textBoxSearchServer'
    $textBoxSearch.Text = 'Search VMs...'
    $toolbar.Controls.Add($textBoxSearch)

    # State filter dropdown
    $comboBoxFilter = New-Object System.Windows.Forms.ComboBox
    $comboBoxFilter.Location = New-Object System.Drawing.Point(530, 14)
    $comboBoxFilter.Size = New-Object System.Drawing.Size(140, 28)
    $comboBoxFilter.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $comboBoxFilter.DropDownStyle = 'DropDownList'
    $comboBoxFilter.BackColor = $script:ColorInputBg
    $comboBoxFilter.ForeColor = $script:ColorText
    $comboBoxFilter.FlatStyle = 'Flat'
    $comboBoxFilter.Items.AddRange(@('All States', 'Running', 'Stopped', 'Paused', 'Saved'))
    $comboBoxFilter.SelectedIndex = 0
    $comboBoxFilter.Name = 'comboBoxFilterServer'
    $toolbar.Controls.Add($comboBoxFilter)

    # Favorites checkbox
    $checkBoxFavorites = New-Object System.Windows.Forms.CheckBox
    $checkBoxFavorites.Location = New-Object System.Drawing.Point(684, 17)
    $checkBoxFavorites.Size = New-Object System.Drawing.Size(130, 22)
    $checkBoxFavorites.Text = 'Favorites Only'
    $checkBoxFavorites.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $checkBoxFavorites.ForeColor = $script:ColorTextSecondary
    $checkBoxFavorites.FlatStyle = 'Flat'
    $checkBoxFavorites.Name = 'checkBoxFavoritesServer'
    $toolbar.Controls.Add($checkBoxFavorites)

    # Export CSV button (success style)
    $buttonExport = New-Object System.Windows.Forms.Button
    $buttonExport.Location = New-Object System.Drawing.Point(1140, 11)
    $buttonExport.Size = New-Object System.Drawing.Size(110, 34)
    $buttonExport.Text = 'Export CSV'
    $buttonExport.BackColor = $script:ColorSuccess
    $buttonExport.ForeColor = [System.Drawing.Color]::FromArgb(10, 40, 30)
    $buttonExport.FlatStyle = 'Flat'
    $buttonExport.FlatAppearance.BorderSize = 0
    $buttonExport.FlatAppearance.MouseOverBackColor = $script:ColorSuccessHover
    $buttonExport.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $buttonExport.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonExport.Name = 'buttonExportServer'
    $toolbar.Controls.Add($buttonExport)

    # Refresh button (primary style)
    $buttonRefreshServer = New-Object System.Windows.Forms.Button
    $buttonRefreshServer.Location = New-Object System.Drawing.Point(1260, 11)
    $buttonRefreshServer.Size = New-Object System.Drawing.Size(110, 34)
    $buttonRefreshServer.Text = 'Refresh'
    $buttonRefreshServer.BackColor = $script:ColorPrimary
    $buttonRefreshServer.ForeColor = [System.Drawing.Color]::White
    $buttonRefreshServer.FlatStyle = 'Flat'
    $buttonRefreshServer.FlatAppearance.BorderSize = 0
    $buttonRefreshServer.FlatAppearance.MouseOverBackColor = $script:ColorPrimaryHover
    $buttonRefreshServer.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $buttonRefreshServer.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonRefreshServer.Name = 'buttonRefreshServer'
    $toolbar.Controls.Add($buttonRefreshServer)

    # ── DataGridView ──
    $dataGridServer = New-Object System.Windows.Forms.DataGridView
    $dataGridServer.Location = New-Object System.Drawing.Point(20, 70)
    $dataGridServer.Size = New-Object System.Drawing.Size(1460, 670)
    $dataGridServer.AllowUserToAddRows = $false
    $dataGridServer.AllowUserToDeleteRows = $false
    $dataGridServer.ReadOnly = $true
    $dataGridServer.SelectionMode = 'FullRowSelect'
    $dataGridServer.MultiSelect = $false
    $dataGridServer.AutoSizeColumnsMode = 'Fill'
    $dataGridServer.BackgroundColor = $script:ColorBackground
    $dataGridServer.BorderStyle = 'None'
    $dataGridServer.GridColor = $script:ColorBorder
    $dataGridServer.RowHeadersVisible = $false
    $dataGridServer.CellBorderStyle = 'SingleHorizontal'
    $dataGridServer.EnableHeadersVisualStyles = $false
    $dataGridServer.ColumnHeadersBorderStyle = 'None'
    $dataGridServer.ColumnHeadersDefaultCellStyle.BackColor = $script:ColorGridHeader
    $dataGridServer.ColumnHeadersDefaultCellStyle.ForeColor = $script:ColorTextSecondary
    $dataGridServer.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $dataGridServer.ColumnHeadersDefaultCellStyle.Padding = New-Object System.Windows.Forms.Padding(4)
    $dataGridServer.ColumnHeadersHeight = 38
    $dataGridServer.ColumnHeadersHeightSizeMode = 'DisableResizing'
    $dataGridServer.DefaultCellStyle.BackColor = $script:ColorBackground
    $dataGridServer.DefaultCellStyle.ForeColor = $script:ColorText
    $dataGridServer.DefaultCellStyle.SelectionBackColor = $script:ColorSelection
    $dataGridServer.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridServer.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $dataGridServer.DefaultCellStyle.Padding = New-Object System.Windows.Forms.Padding(4, 2, 4, 2)
    $dataGridServer.RowTemplate.Height = 32
    $dataGridServer.AlternatingRowsDefaultCellStyle.BackColor = $script:ColorGridAlt
    $dataGridServer.AlternatingRowsDefaultCellStyle.ForeColor = $script:ColorText
    $dataGridServer.Name = 'dataGridServer'
    Enable-DoubleBuffering -Control $dataGridServer
    $panel.Controls.Add($dataGridServer)

    # Summary label
    $labelSummaryServer = New-Object System.Windows.Forms.Label
    $labelSummaryServer.Location = New-Object System.Drawing.Point(20, 748)
    $labelSummaryServer.Size = New-Object System.Drawing.Size(1460, 24)
    $labelSummaryServer.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $labelSummaryServer.ForeColor = $script:ColorTextDim
    $labelSummaryServer.Name = 'labelSummaryServer'
    $panel.Controls.Add($labelSummaryServer)

    return $panel
}

# ═══════════════════════════════════════════════════════════════════════════════
# Snapshot Management Panel
# ═══════════════════════════════════════════════════════════════════════════════
function New-SnapshotManagementPanel {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 106)
    $panel.Size = New-Object System.Drawing.Size(1500, 794)
    $panel.BackColor = $script:ColorBackground
    $panel.Visible = $false
    $panel.Name = 'panelSnapshot'

    # ── Toolbar area ──
    $toolbar = New-Object System.Windows.Forms.Panel
    $toolbar.Location = New-Object System.Drawing.Point(0, 0)
    $toolbar.Size = New-Object System.Drawing.Size(1500, 56)
    $toolbar.BackColor = $script:ColorSurface
    $panel.Controls.Add($toolbar)

    $toolbarBorder = New-Object System.Windows.Forms.Panel
    $toolbarBorder.Location = New-Object System.Drawing.Point(0, 55)
    $toolbarBorder.Size = New-Object System.Drawing.Size(1500, 1)
    $toolbarBorder.BackColor = $script:ColorBorder
    $toolbar.Controls.Add($toolbarBorder)

    # Section title
    $labelSnapshotTitle = New-Object System.Windows.Forms.Label
    $labelSnapshotTitle.Location = New-Object System.Drawing.Point(20, 0)
    $labelSnapshotTitle.Size = New-Object System.Drawing.Size(220, 55)
    $labelSnapshotTitle.Text = 'Snapshot Management'
    $labelSnapshotTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 13)
    $labelSnapshotTitle.ForeColor = $script:ColorText
    $labelSnapshotTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $toolbar.Controls.Add($labelSnapshotTitle)

    # ── Left sidebar: VM List ──
    $sidebarPanel = New-Object System.Windows.Forms.Panel
    $sidebarPanel.Location = New-Object System.Drawing.Point(0, 56)
    $sidebarPanel.Size = New-Object System.Drawing.Size(350, 738)
    $sidebarPanel.BackColor = $script:ColorSurface

    # Sidebar right border
    $sidebarBorder = New-Object System.Windows.Forms.Panel
    $sidebarBorder.Location = New-Object System.Drawing.Point(349, 0)
    $sidebarBorder.Size = New-Object System.Drawing.Size(1, 738)
    $sidebarBorder.BackColor = $script:ColorBorder
    $sidebarPanel.Controls.Add($sidebarBorder)

    # VM list header
    $labelVMs = New-Object System.Windows.Forms.Label
    $labelVMs.Location = New-Object System.Drawing.Point(16, 12)
    $labelVMs.Size = New-Object System.Drawing.Size(200, 22)
    $labelVMs.Text = 'Virtual Machines'
    $labelVMs.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $labelVMs.ForeColor = $script:ColorTextSecondary
    $sidebarPanel.Controls.Add($labelVMs)

    # VM search box
    $textBoxSearchVM = New-Object System.Windows.Forms.TextBox
    $textBoxSearchVM.Location = New-Object System.Drawing.Point(16, 40)
    $textBoxSearchVM.Size = New-Object System.Drawing.Size(316, 28)
    $textBoxSearchVM.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $textBoxSearchVM.BorderStyle = 'FixedSingle'
    $textBoxSearchVM.BackColor = $script:ColorInputBg
    $textBoxSearchVM.ForeColor = $script:ColorTextDim
    $textBoxSearchVM.Name = 'textBoxSearchVM'
    $textBoxSearchVM.Text = 'Search VMs...'
    $sidebarPanel.Controls.Add($textBoxSearchVM)

    # VM ListBox
    $listBoxVMs = New-Object System.Windows.Forms.ListBox
    $listBoxVMs.Location = New-Object System.Drawing.Point(0, 76)
    $listBoxVMs.Size = New-Object System.Drawing.Size(348, 662)
    $listBoxVMs.SelectionMode = 'MultiExtended'
    $listBoxVMs.BackColor = $script:ColorSurface
    $listBoxVMs.ForeColor = $script:ColorText
    $listBoxVMs.BorderStyle = 'None'
    $listBoxVMs.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $listBoxVMs.ItemHeight = 26
    $listBoxVMs.Name = 'listBoxVMs'
    $sidebarPanel.Controls.Add($listBoxVMs)

    $panel.Controls.Add($sidebarPanel)

    # ── Right area: Snapshots ──
    # Snapshot search & filters (inside toolbar, right of title)
    $textBoxSearchSnapshot = New-Object System.Windows.Forms.TextBox
    $textBoxSearchSnapshot.Location = New-Object System.Drawing.Point(370, 14)
    $textBoxSearchSnapshot.Size = New-Object System.Drawing.Size(260, 28)
    $textBoxSearchSnapshot.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $textBoxSearchSnapshot.BorderStyle = 'FixedSingle'
    $textBoxSearchSnapshot.BackColor = $script:ColorInputBg
    $textBoxSearchSnapshot.ForeColor = $script:ColorTextDim
    $textBoxSearchSnapshot.Name = 'textBoxSearchSnapshot'
    $textBoxSearchSnapshot.Text = 'Search snapshots...'
    $toolbar.Controls.Add($textBoxSearchSnapshot)

    # Age filter dropdown
    $comboBoxAgeFilter = New-Object System.Windows.Forms.ComboBox
    $comboBoxAgeFilter.Location = New-Object System.Drawing.Point(640, 14)
    $comboBoxAgeFilter.Size = New-Object System.Drawing.Size(160, 28)
    $comboBoxAgeFilter.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $comboBoxAgeFilter.DropDownStyle = 'DropDownList'
    $comboBoxAgeFilter.BackColor = $script:ColorInputBg
    $comboBoxAgeFilter.ForeColor = $script:ColorText
    $comboBoxAgeFilter.FlatStyle = 'Flat'
    $comboBoxAgeFilter.Items.AddRange(@('All Ages', 'Older than 7 days', 'Older than 30 days', 'Older than 90 days'))
    $comboBoxAgeFilter.SelectedIndex = 0
    $comboBoxAgeFilter.Name = 'comboBoxAgeFilter'
    $toolbar.Controls.Add($comboBoxAgeFilter)

    # Export CSV button
    $buttonExportSnapshot = New-Object System.Windows.Forms.Button
    $buttonExportSnapshot.Location = New-Object System.Drawing.Point(1020, 11)
    $buttonExportSnapshot.Size = New-Object System.Drawing.Size(110, 34)
    $buttonExportSnapshot.Text = 'Export CSV'
    $buttonExportSnapshot.BackColor = $script:ColorSuccess
    $buttonExportSnapshot.ForeColor = [System.Drawing.Color]::FromArgb(10, 40, 30)
    $buttonExportSnapshot.FlatStyle = 'Flat'
    $buttonExportSnapshot.FlatAppearance.BorderSize = 0
    $buttonExportSnapshot.FlatAppearance.MouseOverBackColor = $script:ColorSuccessHover
    $buttonExportSnapshot.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $buttonExportSnapshot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonExportSnapshot.Name = 'buttonExportSnapshot'
    $toolbar.Controls.Add($buttonExportSnapshot)

    # Refresh button
    $buttonRefreshSnapshot = New-Object System.Windows.Forms.Button
    $buttonRefreshSnapshot.Location = New-Object System.Drawing.Point(1140, 11)
    $buttonRefreshSnapshot.Size = New-Object System.Drawing.Size(110, 34)
    $buttonRefreshSnapshot.Text = 'Refresh'
    $buttonRefreshSnapshot.BackColor = $script:ColorPrimary
    $buttonRefreshSnapshot.ForeColor = [System.Drawing.Color]::White
    $buttonRefreshSnapshot.FlatStyle = 'Flat'
    $buttonRefreshSnapshot.FlatAppearance.BorderSize = 0
    $buttonRefreshSnapshot.FlatAppearance.MouseOverBackColor = $script:ColorPrimaryHover
    $buttonRefreshSnapshot.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $buttonRefreshSnapshot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonRefreshSnapshot.Name = 'buttonRefreshSnapshot'
    $toolbar.Controls.Add($buttonRefreshSnapshot)

    # ── Snapshot DataGridView ──
    $dataGridSnapshots = New-Object System.Windows.Forms.DataGridView
    $dataGridSnapshots.Location = New-Object System.Drawing.Point(366, 70)
    $dataGridSnapshots.Size = New-Object System.Drawing.Size(1114, 600)
    $dataGridSnapshots.AllowUserToAddRows = $false
    $dataGridSnapshots.AllowUserToDeleteRows = $false
    $dataGridSnapshots.ReadOnly = $true
    $dataGridSnapshots.SelectionMode = 'FullRowSelect'
    $dataGridSnapshots.MultiSelect = $true
    $dataGridSnapshots.AutoSizeColumnsMode = 'Fill'
    $dataGridSnapshots.BackgroundColor = $script:ColorBackground
    $dataGridSnapshots.BorderStyle = 'None'
    $dataGridSnapshots.GridColor = $script:ColorBorder
    $dataGridSnapshots.RowHeadersVisible = $false
    $dataGridSnapshots.CellBorderStyle = 'SingleHorizontal'
    $dataGridSnapshots.EnableHeadersVisualStyles = $false
    $dataGridSnapshots.ColumnHeadersBorderStyle = 'None'
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.BackColor = $script:ColorGridHeader
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.ForeColor = $script:ColorTextSecondary
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $dataGridSnapshots.ColumnHeadersDefaultCellStyle.Padding = New-Object System.Windows.Forms.Padding(4)
    $dataGridSnapshots.ColumnHeadersHeight = 38
    $dataGridSnapshots.ColumnHeadersHeightSizeMode = 'DisableResizing'
    $dataGridSnapshots.DefaultCellStyle.BackColor = $script:ColorBackground
    $dataGridSnapshots.DefaultCellStyle.ForeColor = $script:ColorText
    $dataGridSnapshots.DefaultCellStyle.SelectionBackColor = $script:ColorSelection
    $dataGridSnapshots.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridSnapshots.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $dataGridSnapshots.DefaultCellStyle.Padding = New-Object System.Windows.Forms.Padding(4, 2, 4, 2)
    $dataGridSnapshots.RowTemplate.Height = 32
    $dataGridSnapshots.AlternatingRowsDefaultCellStyle.BackColor = $script:ColorGridAlt
    $dataGridSnapshots.AlternatingRowsDefaultCellStyle.ForeColor = $script:ColorText
    $dataGridSnapshots.Name = 'dataGridSnapshots'
    Enable-DoubleBuffering -Control $dataGridSnapshots
    $panel.Controls.Add($dataGridSnapshots)

    # ── Action buttons bar ──
    $actionBar = New-Object System.Windows.Forms.Panel
    $actionBar.Location = New-Object System.Drawing.Point(366, 680)
    $actionBar.Size = New-Object System.Drawing.Size(1114, 50)
    $actionBar.BackColor = $script:ColorBackground
    $panel.Controls.Add($actionBar)

    # Delete button (danger)
    $buttonDelete = New-Object System.Windows.Forms.Button
    $buttonDelete.Location = New-Object System.Drawing.Point(0, 5)
    $buttonDelete.Size = New-Object System.Drawing.Size(150, 38)
    $buttonDelete.Text = 'Delete Selected'
    $buttonDelete.Enabled = $false
    $buttonDelete.BackColor = $script:ColorDanger
    $buttonDelete.ForeColor = [System.Drawing.Color]::White
    $buttonDelete.FlatStyle = 'Flat'
    $buttonDelete.FlatAppearance.BorderSize = 0
    $buttonDelete.FlatAppearance.MouseOverBackColor = $script:ColorDangerHover
    $buttonDelete.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $buttonDelete.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonDelete.Name = 'buttonDelete'
    $actionBar.Controls.Add($buttonDelete)

    # Select All (subtle)
    $buttonSelectAll = New-Object System.Windows.Forms.Button
    $buttonSelectAll.Location = New-Object System.Drawing.Point(164, 5)
    $buttonSelectAll.Size = New-Object System.Drawing.Size(110, 38)
    $buttonSelectAll.Text = 'Select All'
    $buttonSelectAll.Enabled = $false
    $buttonSelectAll.BackColor = $script:ColorSurfaceHover
    $buttonSelectAll.ForeColor = $script:ColorTextSecondary
    $buttonSelectAll.FlatStyle = 'Flat'
    $buttonSelectAll.FlatAppearance.BorderSize = 0
    $buttonSelectAll.FlatAppearance.MouseOverBackColor = $script:ColorSurfaceBright
    $buttonSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonSelectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonSelectAll.Name = 'buttonSelectAll'
    $actionBar.Controls.Add($buttonSelectAll)

    # Deselect All (subtle)
    $buttonDeselectAll = New-Object System.Windows.Forms.Button
    $buttonDeselectAll.Location = New-Object System.Drawing.Point(284, 5)
    $buttonDeselectAll.Size = New-Object System.Drawing.Size(110, 38)
    $buttonDeselectAll.Text = 'Deselect All'
    $buttonDeselectAll.Enabled = $false
    $buttonDeselectAll.BackColor = $script:ColorSurfaceHover
    $buttonDeselectAll.ForeColor = $script:ColorTextSecondary
    $buttonDeselectAll.FlatStyle = 'Flat'
    $buttonDeselectAll.FlatAppearance.BorderSize = 0
    $buttonDeselectAll.FlatAppearance.MouseOverBackColor = $script:ColorSurfaceBright
    $buttonDeselectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonDeselectAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $buttonDeselectAll.Name = 'buttonDeselectAll'
    $actionBar.Controls.Add($buttonDeselectAll)

    # Summary label
    $labelSummary = New-Object System.Windows.Forms.Label
    $labelSummary.Location = New-Object System.Drawing.Point(366, 740)
    $labelSummary.Size = New-Object System.Drawing.Size(1114, 24)
    $labelSummary.Text = ''
    $labelSummary.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $labelSummary.ForeColor = $script:ColorTextDim
    $labelSummary.Name = 'labelSummary'
    $panel.Controls.Add($labelSummary)

    return $panel
}

# ═══════════════════════════════════════════════════════════════════════════════
# Utility: Find Control By Name (recursive)
# ═══════════════════════════════════════════════════════════════════════════════
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

Export-ModuleMember -Function New-MainForm, New-CustomTitleBar, New-ConnectionPanel, New-MenuPanel, New-ServerManagementPanel, New-SnapshotManagementPanel, Find-ControlByName, Add-ModernScrollbar, Add-ModernListBoxScrollbar
