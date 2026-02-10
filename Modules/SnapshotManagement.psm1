# SnapshotManagement.psm1 - Snapshot operations

# Helper to compute human-readable age text from a TimeSpan
function Get-AgeText {
    param([TimeSpan]$Age)

    if ($Age.TotalDays -ge 1) {
        $days = [Math]::Floor($Age.TotalDays)
        $hours = $Age.Hours
        $dayLabel = if ($days -eq 1) { "day" } else { "days" }
        return "{0} {1}, {2} hours" -f $days, $dayLabel, $hours
    } elseif ($Age.TotalHours -ge 1) {
        return "{0} hours, {1} minutes" -f [Math]::Floor($Age.TotalHours), $Age.Minutes
    } else {
        return "{0} minutes" -f [Math]::Floor($Age.TotalMinutes)
    }
}

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

                $allSnapshots += [PSCustomObject]@{
                    Node = $node
                    VMName = $vm.Name
                    SnapshotName = $snapshot.Name
                    CreationTime = $snapshot.CreationTime
                    Age = Get-AgeText -Age $age
                    AgeDays = [Math]::Round($age.TotalDays, 2)
                    Snapshot = $snapshot
                }
            }
        }
        catch {
            Write-Warning "Error getting snapshots for $($vmData.VM.Name): $($_.Exception.Message)"
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
            if ($SnapshotObject) {
                # Try using the snapshot object directly
                Remove-VMSnapshot -VMSnapshot $SnapshotObject -Confirm:$false -ErrorAction Stop
            } else {
                # Fallback: look up the snapshot by name (handles cached/stale objects)
                $snapshot = Get-VMSnapshot -VMName $VMName -Name $SnapshotName -ErrorAction Stop
                Remove-VMSnapshot -VMSnapshot $snapshot -Confirm:$false -ErrorAction Stop
            }
            return @{ Success = $true; Error = $null }
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

# Progressive loading version for snapshots
function Get-VMSnapshotsProgressive {
    param(
        [array]$VMData,
        [hashtable]$SyncHash
    )

    $SyncHash.TotalVMs = $VMData.Count
    $SyncHash.ProcessedVMs = 0
    $SyncHash.Snapshots = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $SyncHash.IsComplete = $false
    $SyncHash.CurrentVM = ""

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM
            $SyncHash.CurrentVM = $vm.Name

            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $snapshots = Get-VMSnapshot -VM $vm -ErrorAction Stop
            } else {
                $snapshots = Get-VMSnapshot -VMName $vm.Name -ComputerName $node -ErrorAction Stop
            }

            foreach ($snapshot in $snapshots) {
                $age = (Get-Date) - $snapshot.CreationTime

                $snapshotItem = [PSCustomObject]@{
                    Node = $node
                    VMName = $vm.Name
                    SnapshotName = $snapshot.Name
                    CreationTime = $snapshot.CreationTime
                    Age = Get-AgeText -Age $age
                    AgeDays = [Math]::Round($age.TotalDays, 2)
                    Snapshot = $snapshot
                }

                [void]$SyncHash.Snapshots.Add($snapshotItem)
            }

            $SyncHash.ProcessedVMs++
        }
        catch {
            Write-Warning "Error getting snapshots for $($vmData.VM.Name): $($_.Exception.Message)"
            $SyncHash.ProcessedVMs++
        }
    }

    $SyncHash.IsComplete = $true
    return $SyncHash.Snapshots
}

Export-ModuleMember -Function Get-VMSnapshotsAsync, Remove-VMSnapshotFromNode, Get-VMSnapshotsProgressive
