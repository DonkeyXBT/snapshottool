# SnapshotManagement.psm1 - Snapshot operations

function Get-VMSnapshotsAsync {
    param([array]$VMData)

    $allSnapshots = @()

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
            }
        }
        catch {
            Write-Warning "Error getting snapshots for $($vmData.Name): $($_.Exception.Message)"
        }
    }

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
                Remove-VMSnapshot -VMSnapshot $SnapshotObject -Confirm:$false -ErrorAction Stop
                return @{ Success = $true; Error = $null }
            }
        } else {
            # Remote deletion using Invoke-Command
            Invoke-Command -ComputerName $Node -ScriptBlock {
                param($VMName, $SnapshotName)
                $snapshot = Get-VMSnapshot -VMName $VMName -Name $SnapshotName -ErrorAction Stop
                Remove-VMSnapshot -VMSnapshot $snapshot -Confirm:$false -ErrorAction Stop
            } -ArgumentList $VMName, $SnapshotName -ErrorAction Stop
            return @{ Success = $true; Error = $null }
        }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

Export-ModuleMember -Function Get-VMSnapshotsAsync, Remove-VMSnapshotFromNode
