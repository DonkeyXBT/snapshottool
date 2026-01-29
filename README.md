# Hyper-V Server Management Tool

A PowerShell GUI tool for managing Hyper-V virtual machines and snapshots across multiple hosts. Built with Windows Forms, it provides a modern dark-themed interface for server monitoring, snapshot lifecycle management, and multi-node administration.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-blue)
![Hyper--V](https://img.shields.io/badge/Hyper--V-Required-green)
![Version](https://img.shields.io/badge/Version-3.0-orange)

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Version History](#version-history)
- [License](#license)

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
| Statistics | Snapshot totals and count of snapshots older than 7 days |

### Search & Filtering
- **Real-time search** across VM names, IP addresses, node names, and OS
- **State filtering** - Filter VMs by state (Running, Stopped, Paused, Saved)
- **Age filtering** - Filter snapshots by age threshold (7, 30, or 90 days)
- **Favorites** - Mark VMs as favorites and filter to show only favorites

### Data & Export
- **CSV Export** - Export server information and snapshot data to CSV
- **Favorites System** - Persistent favorites stored in `favorites.json`
- **Connection History** - Auto-saves recently used Hyper-V nodes in `nodes.json`
- **Data Caching** - Cached server info and snapshots for instant display on reconnect

### Notifications & Logging
- **Microsoft Teams** - Automatic webhook notifications when snapshots are deleted
- **File Logging** - All operations logged to `HyperV-ManagementTool.log`
- **Color-coded Status** - Real-time status bar with blue/green/red/orange indicators

### User Interface
- Modern dark theme with indigo accent colors
- Custom draggable title bar with window controls
- Custom scrollbars with hover effects
- Card-based main menu navigation
- Progressive loading with real-time status updates
- Double-buffered rendering for flicker-free display

## Screenshots

### Main Menu
```
+------------------------------------------------------------------+
| [=] Hyper-V Server Management Tool            [_] [O] [X]        |
|------------------------------------------------------------------|
| Hyper-V Nodes: [server01, server02    ]  [Connect] [Back to Menu]|
| Status: Connected to 2 node(s) - 45 VMs found                   |
|------------------------------------------------------------------|
|                                                                  |
|    +------------------------+    +------------------------+      |
|    |                        |    |                        |      |
|    |   Server Management    |    |  Snapshot Management   |      |
|    |                        |    |                        |      |
|    +------------------------+    +------------------------+      |
|    View IPs, memory, storage     View and manage snapshots       |
|                                                                  |
+------------------------------------------------------------------+
```

### Server Management View
```
+------------------------------------------------------------------+
| [Search VMs...        ] [All States v] [* Favorites] [Refresh]   |
|------------------------------------------------------------------|
| Fav | Node   | VM Name  | State   | OS     | IPs    | Mem | CPU |
|-----|--------|----------|---------|--------|--------|-----|-----|
|  *  | SRV-01 | WebApp   | Running | Win 22 | 10.0.1 | 8GB |  4  |
|     | SRV-01 | DBServer | Running | Win 22 | 10.0.2 | 16G |  8  |
|     | SRV-02 | DevBox   | Stopped | -      | -      | 4GB |  2  |
|------------------------------------------------------------------|
| Showing 3 of 45 VMs                                   [Export]   |
+------------------------------------------------------------------+
```

### Snapshot Management View
```
+------------------------------------------------------------------+
| [Search VMs...] | [Search snapshots...] [All Ages v]   [Refresh] |
|-----------------|------------------------------------------------|
| VMs:            | Node   | VM      | Snapshot    | Age           |
|                 |--------|---------|-------------|---------------|
| * WebApp [Run]  | SRV-01 | WebApp  | pre-update  | 14d 3h 22m    |
|   DBServer[Run] | SRV-01 | WebApp  | weekly-bak  | 7d 12h 5m     |
|   DevBox [Stop] | SRV-02 | DevBox  | test-snap   | 2d 1h 15m     |
|                 |------------------------------------------------|
|                 | [Delete Selected] [Select All] [Deselect All]  |
|                 | Total: 128 snapshots | Older than 7 days: 42   |
+------------------------------------------------------------------+
```

## Requirements

| Requirement | Details |
|-------------|---------|
| PowerShell | 5.1 or later (Windows PowerShell) |
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

4. **Verify connectivity (optional):**
   ```powershell
   Test-WSMan <HOSTNAME>
   ```

## Quick Start

```powershell
# Run with administrator privileges
.\main.ps1
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

- **Node** - Which Hyper-V host the VM runs on
- **VM Name** - The virtual machine name
- **State** - Current VM state (Running, Stopped, Paused, Saved)
- **Operating System** - Guest OS detected via KVP Exchange
- **IP Addresses** - All IPv4 addresses assigned to the VM
- **Memory** - Total, Used, and Available memory in GB
- **CPU Count** - Number of virtual processors
- **Disk** - Virtual disk size and used space in GB

Use the search box and state filter to narrow results. Right-click a VM to add/remove it from favorites.

### Snapshot Management

Click **Snapshot Management** to view and manage snapshots:

- **Left panel** shows all discovered VMs with their state
- **Right panel** shows snapshots with creation time, age, and filtering options

### Deleting Snapshots

1. Select snapshots in the grid (Ctrl+Click for multiple, or use **Select All**)
2. Click **Delete Selected**
3. Confirm the deletion in the dialog
4. The tool deletes snapshots and sends a Teams notification automatically

### Exporting Data

Click **Export** in either view to save the current data as a CSV file. The export respects active filters, so you can export filtered subsets of data.

### Favorites

- **Add**: Right-click a VM in Server Management and select "Add to Favorites"
- **Remove**: Right-click and select "Remove from Favorites"
- **Filter**: Check the "Favorites" checkbox to show only favorited VMs
- Favorites persist across sessions in `favorites.json`

## Configuration

### Teams Webhook

Snapshot deletion events are sent to Microsoft Teams via webhook. To configure:

1. Open `Modules/Common.psm1`
2. Update the `$script:TeamsWebhookUrl` variable on line 5:
   ```powershell
   $script:TeamsWebhookUrl = 'YOUR_WEBHOOK_URL_HERE'
   ```

The notification includes: number of deleted snapshots, details of each, and the username/computer that performed the action.

### Log File

All operations are logged to `HyperV-ManagementTool.log` in the script directory. Log entries include timestamps and severity levels:

```
[2026-01-29 14:30:15] [INFO] Connecting to nodes: HyperV-01, HyperV-02
[2026-01-29 14:30:25] [SUCCESS] Successfully loaded 45 VMs and 128 snapshots
[2026-01-29 14:31:10] [ERROR] Failed to delete snapshot 'old-snap' from VM 'WebApp'
```

### Cache Files

The tool generates these files for performance:

| File | Purpose |
|------|---------|
| `serverinfo.json` | Cached VM information for instant display |
| `snapshots.json` | Cached snapshot data |
| `favorites.json` | Persistent VM favorites |
| `nodes.json` | Connection history with usage tracking |

## Architecture

```
snapshottool/
|-- main.ps1                        # Entry point, event handlers, UI orchestration
|-- Modules/
|   |-- Common.psm1                 # Logging, notifications, favorites, caching
|   |-- ServerManagement.psm1       # VM information gathering (local + remote)
|   |-- SnapshotManagement.psm1     # Snapshot retrieval and deletion
|   |-- UIComponents.psm1           # Windows Forms UI components, dark theme
|-- favorites.json                  # User favorites (auto-generated)
|-- serverinfo.json                 # Server info cache (auto-generated)
|-- snapshots.json                  # Snapshot cache (auto-generated)
|-- nodes.json                      # Connection history (auto-generated)
|-- HyperV-ManagementTool.log       # Application log (auto-generated)
```

### Design Principles

- **Modular**: Each module handles a single concern (UI, data, operations)
- **Async**: Background runspaces prevent UI freezing during data collection
- **Progressive**: Data loads and displays incrementally as VMs are processed
- **Cached**: JSON-based caching enables instant display while refreshing in background
- **Safe**: Confirmation dialogs and detailed logging for all destructive operations

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
- Domain Administrators have access by default

### Cannot Connect to Remote Host
```powershell
# Test WinRM connectivity
Test-WSMan <HOSTNAME>

# Check firewall (TCP 5985 for HTTP, 5986 for HTTPS)
Test-NetConnection <HOSTNAME> -Port 5985

# Test basic connectivity
Test-Connection <HOSTNAME>
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

| Version | Date | Changes |
|---------|------|---------|
| 3.0 | 2026-01-29 | Modern dark theme UI, custom scrollbars, connection history |
| 2.1 | 2026-01-19 | Search & filtering, CSV export, favorites system |
| 2.0 | 2026-01-19 | Server management module, modular architecture |
| 1.0 | 2026-01-09 | Initial snapshot management tool |

## License

This tool is provided as-is for managing Hyper-V environments.
