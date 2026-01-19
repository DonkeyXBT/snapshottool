# Common.psm1 - Common utilities, logging, and notifications

# Configuration variables
$script:LogFile = $null
$script:TeamsWebhookUrl = 'https://asapnet.webhook.office.com/webhookb2/e2cb2abf-e3ad-44a2-9ac2-fc75a3e69157@60922053-03d2-40e3-837a-5ca3fca7102b/IncomingWebhook/cf8d6f80c793446793387c866095bb6d/0fae63a6-c28c-4510-983e-92bc30465c6e/V25JJgAkleuQh2-QQcU88NJWNxOj4QcaRikzUgQZrp_qc1'

function Initialize-LogFile {
    param([string]$ScriptPath)

    $logPath = if ($ScriptPath) { $ScriptPath } else { $PWD.Path }
    $script:LogFile = Join-Path $logPath "HyperV-ManagementTool.log"

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

Export-ModuleMember -Function Initialize-LogFile, Write-Log, Send-TeamsNotification, Update-Status
