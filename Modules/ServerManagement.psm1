# ServerManagement.psm1 - Server information gathering functions

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

function Get-ServerInformationAsync {
    param([array]$VMData)

    $serverInfo = @()
    $totalVMs = $VMData.Count
    $currentVM = 0

    Write-ConsoleLog "Starting server information collection for $totalVMs VMs" "INFO"

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM
            $currentVM++

            Write-ConsoleLog "[$currentVM/$totalVMs] Collecting info for VM '$($vm.Name)' on node '$node'" "INFO"

            # Get VM network adapters and IP addresses
            $ipAddresses = @()
            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $networkAdapters = Get-VMNetworkAdapter -VM $vm -ErrorAction SilentlyContinue
                foreach ($adapter in $networkAdapters) {
                    if ($adapter.IPAddresses) {
                        $ipAddresses += $adapter.IPAddresses
                    }
                }
            } else {
                $networkAdapters = Get-VMNetworkAdapter -VMName $vm.Name -ComputerName $node -ErrorAction SilentlyContinue
                foreach ($adapter in $networkAdapters) {
                    if ($adapter.IPAddresses) {
                        $ipAddresses += $adapter.IPAddresses
                    }
                }
            }

            # Filter to IPv4 addresses only
            $ipv4Addresses = $ipAddresses | Where-Object { $_ -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$' }
            $ipAddressString = if ($ipv4Addresses) { $ipv4Addresses -join ", " } else { "N/A" }

            # Get memory information
            $memoryTotalGB = [Math]::Round($vm.MemoryAssigned / 1GB, 2)
            $memoryStartupGB = [Math]::Round($vm.MemoryStartup / 1GB, 2)
            $memoryDemandGB = if ($vm.MemoryDemand) { [Math]::Round($vm.MemoryDemand / 1GB, 2) } else { 0 }
            $memoryAvailableGB = [Math]::Round(($vm.MemoryAssigned - $vm.MemoryDemand) / 1GB, 2)

            # Get guest OS information via KVP Exchange (requires integration services)
            $guestOS = "N/A"
            try {
                if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                    $vmWmi = Get-CimInstance -Namespace "root\virtualization\v2" -ClassName "Msvm_ComputerSystem" -Filter "ElementName='$($vm.Name)'" -ErrorAction SilentlyContinue
                    if ($vmWmi) {
                        $kvp = Get-CimAssociatedInstance -InputObject $vmWmi -ResultClassName "Msvm_KvpExchangeComponent" -ErrorAction SilentlyContinue
                        if ($kvp -and $kvp.GuestIntrinsicExchangeItems) {
                            foreach ($item in $kvp.GuestIntrinsicExchangeItems) {
                                $xml = [xml]$item
                                $propName = ($xml.INSTANCE.PROPERTY | Where-Object { $_.NAME -eq 'Name' }).VALUE
                                $propData = ($xml.INSTANCE.PROPERTY | Where-Object { $_.NAME -eq 'Data' }).VALUE
                                if ($propName -eq 'OSName') {
                                    $guestOS = $propData
                                    break
                                }
                            }
                        }
                    }
                } else {
                    $remoteOS = Invoke-Command -ComputerName $node -ScriptBlock {
                        param($VMName)
                        $osName = "N/A"
                        $vmWmi = Get-CimInstance -Namespace "root\virtualization\v2" -ClassName "Msvm_ComputerSystem" -Filter "ElementName='$VMName'" -ErrorAction SilentlyContinue
                        if ($vmWmi) {
                            $kvp = Get-CimAssociatedInstance -InputObject $vmWmi -ResultClassName "Msvm_KvpExchangeComponent" -ErrorAction SilentlyContinue
                            if ($kvp -and $kvp.GuestIntrinsicExchangeItems) {
                                foreach ($item in $kvp.GuestIntrinsicExchangeItems) {
                                    $xml = [xml]$item
                                    $propName = ($xml.INSTANCE.PROPERTY | Where-Object { $_.NAME -eq 'Name' }).VALUE
                                    $propData = ($xml.INSTANCE.PROPERTY | Where-Object { $_.NAME -eq 'Data' }).VALUE
                                    if ($propName -eq 'OSName') {
                                        $osName = $propData
                                        break
                                    }
                                }
                            }
                        }
                        return $osName
                    } -ArgumentList $vm.Name -ErrorAction SilentlyContinue
                    if ($remoteOS) { $guestOS = $remoteOS }
                }
            } catch {
                # OS detection failed, leave as N/A
            }

            # Get disk information
            $diskSizeGB = 0
            $diskUsedGB = 0
            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $vhds = Get-VMHardDiskDrive -VM $vm -ErrorAction SilentlyContinue
                foreach ($vhd in $vhds) {
                    if ($vhd.Path -and (Test-Path $vhd.Path)) {
                        $vhdInfo = Get-VHD -Path $vhd.Path -ErrorAction SilentlyContinue
                        if ($vhdInfo) {
                            $diskSizeGB += [Math]::Round($vhdInfo.Size / 1GB, 2)
                            $diskUsedGB += [Math]::Round($vhdInfo.FileSize / 1GB, 2)
                        }
                    }
                }
            } else {
                try {
                    $vhds = Get-VMHardDiskDrive -VMName $vm.Name -ComputerName $node -ErrorAction SilentlyContinue
                    foreach ($vhd in $vhds) {
                        if ($vhd.Path) {
                            $vhdInfo = Invoke-Command -ComputerName $node -ScriptBlock {
                                param($VhdPath)
                                if (Test-Path $VhdPath) {
                                    Get-VHD -Path $VhdPath -ErrorAction SilentlyContinue
                                }
                            } -ArgumentList $vhd.Path -ErrorAction SilentlyContinue

                            if ($vhdInfo) {
                                $diskSizeGB += [Math]::Round($vhdInfo.Size / 1GB, 2)
                                $diskUsedGB += [Math]::Round($vhdInfo.FileSize / 1GB, 2)
                            }
                        }
                    }
                }
                catch {
                    # Remote disk access failed, skip
                }
            }

            $serverInfo += [PSCustomObject]@{
                Node = $node
                VMName = $vm.Name
                State = $vm.State
                GuestOS = $guestOS
                IPAddresses = $ipAddressString
                MemoryTotalGB = $memoryTotalGB
                MemoryUsedGB = $memoryDemandGB
                MemoryAvailableGB = $memoryAvailableGB
                ProcessorCount = $vm.ProcessorCount
                DiskSizeGB = if ($diskSizeGB -gt 0) { $diskSizeGB } else { "N/A" }
                DiskUsedGB = if ($diskUsedGB -gt 0) { $diskUsedGB } else { "N/A" }
            }
        }
        catch {
            Write-ConsoleLog "Error getting info for VM '$($vm.Name)' on node '$node': $($_.Exception.Message)" "ERROR"
        }
    }

    Write-ConsoleLog "Server information collection complete: $($serverInfo.Count) of $totalVMs VMs processed" "SUCCESS"
    return $serverInfo
}

function Get-VMsFromNodes {
    param([array]$Nodes)

    $allVMs = @()
    $errors = @()
    $totalNodes = $Nodes.Count
    $currentNode = 0

    Write-ConsoleLog "Discovering VMs from $totalNodes node(s)" "INFO"

    foreach ($node in $Nodes) {
        $currentNode++
        Write-ConsoleLog "[$currentNode/$totalNodes] Connecting to node '$node'" "INFO"
        try {
            if ($node -eq 'localhost' -or $node -eq $env:COMPUTERNAME) {
                $vms = Get-VM -ErrorAction Stop
            } else {
                $vms = Get-VM -ComputerName $node -ErrorAction Stop
            }

            Write-ConsoleLog "[$currentNode/$totalNodes] Found $($vms.Count) VMs on node '$node'" "SUCCESS"

            foreach ($vm in $vms) {
                $allVMs += [PSCustomObject]@{
                    Node = $node
                    VM = $vm
                    Name = $vm.Name
                    State = $vm.State
                    DisplayName = "$($vm.Name) [$($vm.State)] - $node"
                }
            }
        }
        catch {
            $errorMsg = "Error connecting to ${node}: $($_.Exception.Message)"
            Write-ConsoleLog $errorMsg "ERROR"
            $errors += $errorMsg
        }
    }

    Write-ConsoleLog "VM discovery complete: $($allVMs.Count) VMs found across $totalNodes node(s), $($errors.Count) error(s)" "INFO"

    return @{
        VMs = $allVMs
        Errors = $errors
    }
}

Export-ModuleMember -Function Get-ServerInformationAsync, Get-VMsFromNodes
