# SnapshotManagement.psm1 - Snapshot operations

function Write-ConsoleLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $consoleColor = switch ($Level) {
        'INFO'    { 'Cyan' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        default   { 'White' }
    }
    $levelTag = switch ($Level) {
        'INFO'    { 'INF' }
        'WARNING' { 'WRN' }
        'ERROR'   { 'ERR' }
        'SUCCESS' { 'OK ' }
        default   { '---' }
    }
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
    Write-Host "[$levelTag] " -NoNewline -ForegroundColor $consoleColor
    Write-Host $Message -ForegroundColor $consoleColor
}

function Get-VMSnapshotsAsync {
    param([array]$VMData)

    $allSnapshots = @()
    $totalVMs = $VMData.Count
    $currentVM = 0

    Write-ConsoleLog "Scanning snapshots across $totalVMs VMs" "INFO"

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM
            $currentVM++

            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $snapshots = Get-VMSnapshot -VM $vm -ErrorAction Stop
            } else {
                $snapshots = Get-VMSnapshot -VMName $vm.Name -ComputerName $node -ErrorAction Stop
            }

            if ($snapshots -and $snapshots.Count -gt 0) {
                Write-ConsoleLog "[$currentVM/$totalVMs] Found $($snapshots.Count) snapshot(s) for VM '$($vm.Name)' on '$node'" "INFO"
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
            }
        }
        catch {
            Write-ConsoleLog "Error getting snapshots for VM '$($vmData.Name)' on '$($vmData.Node)': $($_.Exception.Message)" "ERROR"
        }
    }

    Write-ConsoleLog "Snapshot scan complete: $($allSnapshots.Count) total snapshots found across $totalVMs VMs" "SUCCESS"
    return $allSnapshots
}

function Remove-VMSnapshotFromNode {
    param(
        [string]$Node,
        [string]$VMName,
        [string]$SnapshotName,
        [object]$SnapshotObject
    )

    try {
        if ($Node -eq 'localhost' -or $Node -eq $env:COMPUTERNAME) {
            # Local deletion using snapshot object
            if ($SnapshotObject) {
                Write-ConsoleLog "Removing snapshot '$SnapshotName' from local VM '$VMName'" "INFO"
                Remove-VMSnapshot -VMSnapshot $SnapshotObject -Confirm:$false -ErrorAction Stop
                Write-ConsoleLog "Snapshot '$SnapshotName' removed from VM '$VMName'" "SUCCESS"
                return @{ Success = $true; Error = $null }
            }
        } else {
            # Remote deletion using Invoke-Command
            Write-ConsoleLog "Removing snapshot '$SnapshotName' from VM '$VMName' on remote node '$Node'" "INFO"
            Invoke-Command -ComputerName $Node -ScriptBlock {
                param($VMName, $SnapshotName)
                $snapshot = Get-VMSnapshot -VMName $VMName -Name $SnapshotName -ErrorAction Stop
                Remove-VMSnapshot -VMSnapshot $snapshot -Confirm:$false -ErrorAction Stop
            } -ArgumentList $VMName, $SnapshotName -ErrorAction Stop
            Write-ConsoleLog "Snapshot '$SnapshotName' removed from VM '$VMName' on node '$Node'" "SUCCESS"
            return @{ Success = $true; Error = $null }
        }
    }
    catch {
        Write-ConsoleLog "Failed to remove snapshot '$SnapshotName' from VM '$VMName' on node '$Node': $($_.Exception.Message)" "ERROR"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

Export-ModuleMember -Function Get-VMSnapshotsAsync, Remove-VMSnapshotFromNode
