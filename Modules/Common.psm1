# Common.psm1 - Common utilities, logging, and notifications

# Configuration variables
$script:LogFile = $null
$script:TeamsWebhookUrl = 'https://asapnet.webhook.office.com/webhookb2/e2cb2abf-e3ad-44a2-9ac2-fc75a3e69157@60922053-03d2-40e3-837a-5ca3fca7102b/IncomingWebhook/cf8d6f80c793446793387c866095bb6d/0fae63a6-c28c-4510-983e-92bc30465c6e/V25JJgAkleuQh2-QQcU88NJWNxOj4QcaRikzUgQZrp_qc1'

function Initialize-LogFile {
    param([string]$ScriptPath)

    $logPath = if ($ScriptPath) { $ScriptPath } else { $PWD.Path }
    $script:LogFile = Join-Path $logPath "HyperV-ManagementTool.log"

    # Ensure parent directory exists and create log file
    try {
        # Get the directory path
        $logDirectory = Split-Path -Path $script:LogFile -Parent

        # Create directory if it doesn't exist
        if (-not (Test-Path $logDirectory)) {
            New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
        }

        # Create log file if it doesn't exist
        if (-not (Test-Path $script:LogFile)) {
            New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
        }
    }
    catch {
        Write-Warning "Failed to create log file: $($_.Exception.Message)"
    }

    Write-Log "Hyper-V Server Management Tool started" "INFO"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    try {
        if ($script:LogFile) {
            Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction Stop
        }
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

function Send-TeamsNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Color = "00FF00"  # Green by default
    )

    try {
        $body = @{
            "@type" = "MessageCard"
            "@context" = "https://schema.org/extensions"
            "summary" = $Title
            "themeColor" = $Color
            "title" = $Title
            "text" = $Message
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $script:TeamsWebhookUrl -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Log "Teams notification sent: $Title" "INFO"
    }
    catch {
        Write-Log "Failed to send Teams notification: $($_.Exception.Message)" "ERROR"
    }
}

function Update-Status {
    param(
        [System.Windows.Forms.Label]$StatusLabel,
        [string]$Message,
        [string]$Color = 'Blue'
    )

    if ($StatusLabel) {
        $StatusLabel.Text = $Message
        $StatusLabel.ForeColor = [System.Drawing.Color]::FromName($Color)
        $StatusLabel.Parent.Refresh()
    }
}

function Export-ToCSV {
    param(
        [Parameter(Mandatory=$true)]
        [System.Data.DataTable]$DataTable,
        [Parameter(Mandatory=$true)]
        [string]$DefaultFileName
    )

    try {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $saveFileDialog.FileName = $DefaultFileName
        $saveFileDialog.Title = "Export to CSV"

        if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $csvData = @()
            foreach ($row in $DataTable.Rows) {
                $rowData = @{}
                foreach ($column in $DataTable.Columns) {
                    $rowData[$column.ColumnName] = $row[$column.ColumnName]
                }
                $csvData += New-Object PSObject -Property $rowData
            }

            $csvData | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation -Encoding UTF8
            Write-Log "Exported data to CSV: $($saveFileDialog.FileName)" "SUCCESS"
            return $true
        }
        return $false
    }
    catch {
        Write-Log "Failed to export to CSV: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Favorites management
$script:FavoritesFile = $null
$script:Favorites = @()

function Initialize-Favorites {
    param([string]$ScriptPath)

    $favPath = if ($ScriptPath) { $ScriptPath } else { $PWD.Path }
    $script:FavoritesFile = Join-Path $favPath "favorites.json"

    # Load existing favorites
    if (Test-Path $script:FavoritesFile) {
        try {
            $script:Favorites = Get-Content $script:FavoritesFile -Raw | ConvertFrom-Json
            if (-not $script:Favorites) { $script:Favorites = @() }
        }
        catch {
            $script:Favorites = @()
        }
    }
}

function Add-Favorite {
    param(
        [string]$Node,
        [string]$VMName
    )

    $favorite = @{
        Node = $Node
        VMName = $VMName
        AddedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    if ($script:Favorites -notcontains $favorite) {
        $script:Favorites += $favorite
        Save-Favorites
        Write-Log "Added favorite: $VMName on $Node" "INFO"
        return $true
    }
    return $false
}

function Remove-Favorite {
    param(
        [string]$Node,
        [string]$VMName
    )

    $script:Favorites = $script:Favorites | Where-Object { -not ($_.Node -eq $Node -and $_.VMName -eq $VMName) }
    Save-Favorites
    Write-Log "Removed favorite: $VMName on $Node" "INFO"
}

function Get-Favorites {
    return $script:Favorites
}

function Test-IsFavorite {
    param(
        [string]$Node,
        [string]$VMName
    )

    return ($script:Favorites | Where-Object { $_.Node -eq $Node -and $_.VMName -eq $VMName }).Count -gt 0
}

function Save-Favorites {
    try {
        $script:Favorites | ConvertTo-Json | Set-Content -Path $script:FavoritesFile -Encoding UTF8
    }
    catch {
        Write-Log "Failed to save favorites: $($_.Exception.Message)" "ERROR"
    }
}

Export-ModuleMember -Function Initialize-LogFile, Write-Log, Send-TeamsNotification, Update-Status, Export-ToCSV, Initialize-Favorites, Add-Favorite, Remove-Favorite, Get-Favorites, Test-IsFavorite
