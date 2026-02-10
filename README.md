# HyperV Manager

A PowerShell GUI tool for managing Hyper-V virtual machines and snapshots across multiple hosts. Features a modern dark-themed interface for server monitoring, snapshot lifecycle management, and multi-node administration.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![Hyper--V](https://img.shields.io/badge/Hyper--V-Required-green)
![Version](https://img.shields.io/badge/Version-3.1-orange)

## Features

### Server Management
| Feature | Description |
|---------|-------------|
| IP Address Discovery | View all IPv4 addresses assigned to each VM |
| Memory Monitoring | Track total, used, and available memory (GB) per VM |
| Storage Monitoring | Monitor virtual hard drive size and usage |
| CPU Information | View processor count per VM |
| VM State Tracking | Real-time state display (Running, Stopped, Paused, Saved) |
| Guest OS Detection | Identify the guest operating system via Hyper-V KVP Exchange |

### Snapshot Management
| Feature | Description |
|---------|-------------|
| Multi-Host Support | Connect to multiple Hyper-V nodes simultaneously |
| Auto VM Discovery | Automatically finds all VMs on connected hosts |
| Snapshot Overview | View all snapshots with creation date and calculated age |
| Batch Deletion | Select and delete multiple snapshots at once |
| Age Tracking | Human-readable age display (days, hours, minutes) |
| Age Filtering | Filter snapshots older than 7, 30, or 90 days |

### Search & Filtering
- **Real-time search** across VM names, IP addresses, node names, and OS
- **State filtering** — filter VMs by Running, Stopped, Paused, or Saved
- **Age filtering** — filter snapshots by age threshold (7, 30, or 90 days)
- **Favorites** — mark VMs as favorites and filter to show only favorites

### Data & Export
- **CSV Export** — export server information and snapshot data
- **Favorites** — persistent favorites stored in `favorites.json`
- **Connection History** — auto-saves recently used nodes in `nodes.json`
- **Caching** — cached data for instant display on reconnect

### Notifications & Logging
- **Microsoft Teams** — webhook notifications on snapshot deletion
- **File Logging** — all operations logged to `HyperV-Manager.log`
- **Color-coded Status** — real-time status bar with color indicators

### User Interface
- Modern dark theme with indigo accent colors
- Custom draggable title bar with window controls
- Custom scrollbars with hover effects
- Card-based main menu navigation
- Progressive loading with real-time status updates
- Double-buffered rendering for flicker-free display

## Requirements

| Requirement | Details |
|-------------|---------|
| PowerShell | 5.1 or later |
| Hyper-V Module | Included with the Hyper-V role |
| Permissions | Administrator privileges on Hyper-V hosts |
| Remote Access | WinRM enabled for remote host connections |
| OS | Windows Server 2016+ or Windows 10/11 with Hyper-V |

## Installation

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/DonkeyXBT/snapshottool.git
   cd snapshottool
   ```

2. **Verify Hyper-V module is available:**
   ```powershell
   Get-Module -ListAvailable Hyper-V
   ```

3. **For remote hosts, ensure WinRM is configured:**
   ```powershell
   # On the remote Hyper-V host (run as Administrator)
   Enable-PSRemoting -Force
   ```

## Quick Start

```powershell
# Run with administrator privileges
.\HyperV-Manager.ps1
```

1. Enter your Hyper-V host(s) in the connection bar (comma-separated for multiple)
2. Click **Connect**
3. Choose **Server Management** or **Snapshot Management** from the main menu

## Usage Guide

### Connecting to Hosts

| Input | Example |
|-------|---------|
| Local machine | `localhost` |
| Single remote host | `HyperV-Server01` |
| Multiple hosts | `HyperV-01, HyperV-02, HyperV-03` |

The tool remembers your most recently used nodes and auto-fills them on next launch.

### Server Management

After connecting, click **Server Management** to view detailed VM information:

- **Node** — which Hyper-V host the VM runs on
- **VM Name** — the virtual machine name
- **State** — current VM state (Running, Stopped, Paused, Saved)
- **Operating System** — guest OS detected via KVP Exchange
- **IP Addresses** — all IPv4 addresses assigned to the VM
- **Memory** — total, used, and available memory in GB
- **CPU Count** — number of virtual processors
- **Disk** — virtual disk size and used space in GB

Use the search box and state filter to narrow results. Right-click a VM to add/remove it from favorites.

### Snapshot Management

Click **Snapshot Management** to view and manage snapshots:

- **Left panel** — all discovered VMs with their state
- **Right panel** — snapshots with creation time, age, and filtering options

### Deleting Snapshots

1. Select snapshots in the grid (Ctrl+Click for multiple, or use **Select All**)
2. Click **Delete Selected**
3. Confirm the deletion in the dialog
4. The tool deletes snapshots and sends a Teams notification

### Exporting Data

Click **Export CSV** in either view to save the current data as a CSV file. The export respects active filters.

### Favorites

- **Add**: Right-click a VM in Server Management > "Add to Favorites"
- **Remove**: Right-click > "Remove from Favorites"
- **Filter**: Check "Favorites Only" to show only favorited VMs
- Favorites persist across sessions in `favorites.json`

## Configuration

### Teams Webhook

Snapshot deletion events are sent to Microsoft Teams via webhook. To configure:

1. Open `Modules/Common.psm1`
2. Update the `$script:TeamsWebhookUrl` variable:
   ```powershell
   $script:TeamsWebhookUrl = 'YOUR_WEBHOOK_URL_HERE'
   ```

### Log File

All operations are logged to `HyperV-Manager.log` in the script directory:

```
[2026-01-29 14:30:15] [INFO] Connecting to nodes: HyperV-01, HyperV-02
[2026-01-29 14:30:25] [SUCCESS] Successfully loaded 45 VMs and 128 snapshots
[2026-01-29 14:31:10] [ERROR] Failed to delete snapshot 'old-snap' from VM 'WebApp'
```

### Cache Files

| File | Purpose |
|------|---------|
| `serverinfo.json` | Cached VM information for instant display |
| `snapshots.json` | Cached snapshot data |
| `favorites.json` | Persistent VM favorites |
| `nodes.json` | Connection history with usage tracking |

## Architecture

```
HyperV-Manager.ps1                  # Entry point, event handlers, UI orchestration
Modules/
├── Common.psm1                      # Logging, notifications, favorites, caching
├── ServerManagement.psm1            # VM information gathering (local + remote)
├── SnapshotManagement.psm1          # Snapshot retrieval and deletion
└── UIComponents.psm1                # Windows Forms UI components, dark theme
```

### Design Principles

- **Modular** — each module handles a single concern (UI, data, operations)
- **Async** — background runspaces prevent UI freezing during data collection
- **Progressive** — data loads and displays incrementally as VMs are processed
- **Cached** — JSON-based caching enables instant display while refreshing in background
- **Safe** — confirmation dialogs and logging for all destructive operations

### Hyper-V Cmdlets Used

| Cmdlet | Purpose |
|--------|---------|
| `Get-VM` | Retrieve virtual machines |
| `Get-VMSnapshot` | Retrieve VM snapshots |
| `Remove-VMSnapshot` | Delete snapshots |
| `Get-VMNetworkAdapter` | Get network adapter info and IPs |
| `Get-VMHardDiskDrive` | Get virtual disk information |
| `Get-VHD` | Get VHD/VHDX file details |

## Troubleshooting

### Access Denied
- Run PowerShell as **Administrator**
- Verify membership in the **Hyper-V Administrators** group on remote hosts

### Cannot Connect to Remote Host
```powershell
# Test WinRM connectivity
Test-WSMan <HOSTNAME>

# Check firewall (TCP 5985 for HTTP, 5986 for HTTPS)
Test-NetConnection <HOSTNAME> -Port 5985
```

### Hyper-V Module Not Found
```powershell
# Windows Server
Install-WindowsFeature -Name Hyper-V-PowerShell

# Windows 10/11
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell
```

### Cached Data is Stale
Click **Refresh** in any view to force a fresh data collection from the Hyper-V hosts. Cache age is displayed in the status bar when loading from cache.

## Version History

| Version | Changes |
|---------|---------|
| 3.1 | Renamed to HyperV Manager, fixed pipeline expression error in scrollbar event handlers |
| 3.0 | Modern dark theme UI, custom scrollbars, connection history |
| 2.1 | Search & filtering, CSV export, favorites system |
| 2.0 | Server management module, modular architecture |
| 1.0 | Initial snapshot management tool |

## License

This tool is provided as-is for managing Hyper-V environments.
