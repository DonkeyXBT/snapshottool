# ServerManagement.psm1 - Server information gathering functions

function Get-ServerInformationAsync {
    param([array]$VMData)

    $serverInfo = @()

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM

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
            Write-Warning "Error getting info for $($vm.Name): $($_.Exception.Message)"
        }
    }

    return $serverInfo
}

function Get-VMsFromNodes {
    param([array]$Nodes)

    $allVMs = @()
    $errors = @()

    foreach ($node in $Nodes) {
        try {
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
        }
        catch {
            $errors += "Error connecting to ${node}: $($_.Exception.Message)"
        }
    }

    return @{
        VMs = $allVMs
        Errors = $errors
    }
}

# Progressive loading version - processes VMs one by one and adds to a synchronized collection
function Get-ServerInformationProgressive {
    param(
        [array]$VMData,
        [hashtable]$SyncHash  # Synchronized hashtable for progress reporting
    )

    $SyncHash.TotalVMs = $VMData.Count
    $SyncHash.ProcessedVMs = 0
    $SyncHash.ServerInfo = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $SyncHash.IsComplete = $false

    foreach ($vmData in $VMData) {
        try {
            $node = $vmData.Node
            $vm = $vmData.VM

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
            $memoryDemandGB = if ($vm.MemoryDemand) { [Math]::Round($vm.MemoryDemand / 1GB, 2) } else { 0 }
            $memoryAvailableGB = [Math]::Round(($vm.MemoryAssigned - $vm.MemoryDemand) / 1GB, 2)

            # Get guest OS information
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
                }
            } catch { }

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
            }

            $serverInfoItem = [PSCustomObject]@{
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

            # Add to synchronized collection (UI can read this progressively)
            [void]$SyncHash.ServerInfo.Add($serverInfoItem)
            $SyncHash.ProcessedVMs++
            $SyncHash.CurrentVM = $vm.Name
        }
        catch {
            $SyncHash.ProcessedVMs++
        }
    }

    $SyncHash.IsComplete = $true
    return $SyncHash.ServerInfo
}

Export-ModuleMember -Function Get-ServerInformationAsync, Get-VMsFromNodes, Get-ServerInformationProgressive
