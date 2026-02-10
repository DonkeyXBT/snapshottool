<div align="center">

# HyperV Toolkit

**A modern, dark-themed GUI for managing Hyper-V virtual machines and snapshots across multiple hosts.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/en-us/windows)
[![Hyper-V](https://img.shields.io/badge/Hyper--V-Required-00BCF2?style=for-the-badge&logo=microsoft&logoColor=white)](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)
[![Version](https://img.shields.io/badge/Version-4.0-6366F1?style=for-the-badge)](/)
[![License](https://img.shields.io/badge/License-MIT-34D399?style=for-the-badge)](/)

---

*Built for IT admins and infrastructure engineers who need a fast, intuitive way to monitor and manage their Hyper-V environments.*

</div>

---

## Overview

HyperV Toolkit is a PowerShell-based desktop application that gives you complete visibility into your Hyper-V infrastructure through a sleek, modern dark-themed interface. Connect to one or more Hyper-V hosts, instantly see the status of every VM, and manage snapshots — all from a single window.

### Why HyperV Toolkit?

- **Zero Installation** — Just run the script. No installers, no dependencies beyond PowerShell and Hyper-V.
- **Multi-Host Support** — Connect to multiple Hyper-V nodes simultaneously and see everything in one place.
- **Fast & Responsive** — Progressive loading shows data as it arrives. Cached results give you instant startup.
- **Modern Dark UI** — Custom-rendered Windows 11-style interface with indigo accents and smooth scrolling.

---

## Features

### Server Management

| Feature | Description |
|:--------|:------------|
| **IP Address Discovery** | View all IPv4 addresses assigned to each VM |
| **Memory Monitoring** | Track total, used, and available memory per VM |
| **Storage Monitoring** | Monitor virtual hard drive size and actual disk usage |
| **CPU Information** | View virtual processor count per VM |
| **VM State Tracking** | Real-time state display (Running, Stopped, Paused, Saved) |
| **Guest OS Detection** | Identify guest operating systems via Hyper-V KVP Exchange |

### Snapshot Management

| Feature | Description |
|:--------|:------------|
| **Multi-Host Snapshots** | View snapshots across all connected Hyper-V nodes |
| **Auto VM Discovery** | Automatically discovers all VMs on connected hosts |
| **Age Tracking** | Human-readable age display with precise day/hour breakdowns |
| **Batch Deletion** | Select and delete multiple snapshots at once with confirmation |
| **Age Filtering** | Filter snapshots older than 7, 30, or 90 days |
| **Snapshot Search** | Real-time search across snapshot names, VMs, and nodes |

### Search & Filtering

- **Debounced Real-Time Search** — Instant filtering across VM names, IPs, node names, and OS
- **State Filtering** — Filter VMs by Running, Stopped, Paused, or Saved
- **Age Filtering** — Find stale snapshots older than 7, 30, or 90 days
- **Favorites System** — Star VMs for quick access and filter to show only favorites

### Data & Export

- **CSV Export** — Export server info and snapshot data with one click (respects active filters)
- **Persistent Favorites** — Favorites survive across sessions
- **Connection History** — Auto-saves recently used nodes and prefills on next launch
- **Smart Caching** — Cached data loads instantly while fresh data loads in the background

### Notifications & Logging

- **Microsoft Teams** — Webhook notifications when snapshots are deleted (configurable)
- **Structured Logging** — All operations logged with timestamps and severity levels
- **Log Rotation** — Automatic log file rotation when size exceeds 10 MB
- **Color-Coded Status** — Live status bar with color indicators for every operation

### User Interface

- Modern dark theme with indigo accent colors
- Custom Windows 11-style draggable title bar
- Fully resizable window with responsive layout
- Custom thin scrollbars with hover effects and drag support
- Card-based main menu navigation
- Progressive loading with real-time status updates
- Double-buffered rendering for flicker-free display

---

## Requirements

| Requirement | Details |
|:------------|:--------|
| **PowerShell** | 5.1 or later |
| **Hyper-V Module** | Included with the Hyper-V role |
| **Permissions** | Administrator privileges on Hyper-V hosts |
| **Remote Access** | WinRM enabled for remote host connections |
| **OS** | Windows Server 2016+ or Windows 10/11 with Hyper-V |

---

## Quick Start

### 1. Clone the Repository

```powershell
git clone https://github.com/DonkeyXBT/HyperV-Toolkit.git
cd HyperV-Toolkit
```

### 2. Verify Prerequisites

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Verify Hyper-V module is available
Get-Module -ListAvailable Hyper-V
```

### 3. Launch

```powershell
# Run with administrator privileges
.\HyperV-Manager.ps1
```

### 4. Connect

1. Enter your Hyper-V host(s) in the connection bar (comma-separated for multiple)
2. Click **Connect**
3. Choose **Server Management** or **Snapshot Management** from the main menu

---

## Usage Guide

### Connecting to Hosts

| Input | Example |
|:------|:--------|
| Local machine | `localhost` |
| Single remote host | `HyperV-Server01` |
| Multiple hosts | `HyperV-01, HyperV-02, HyperV-03` |

The tool remembers your most recently used nodes and auto-fills them on next launch.

### Server Management

After connecting, click **Server Management** to view:

- **Node** — Which Hyper-V host the VM runs on
- **VM Name** — The virtual machine name
- **State** — Current VM state (Running, Stopped, Paused, Saved)
- **Operating System** — Guest OS detected via KVP Exchange
- **IP Addresses** — All IPv4 addresses assigned to the VM
- **Memory** — Total, used, and available memory in GB
- **CPU Count** — Number of virtual processors
- **Disk** — Virtual disk size and used space in GB

> Right-click any VM to add or remove it from your Favorites.

### Snapshot Management

Click **Snapshot Management** to view and manage snapshots:

- **Left panel** — All discovered VMs with their state and node
- **Right panel** — Snapshots with creation time, age, and filtering options

### Deleting Snapshots

1. Select snapshots in the grid (Ctrl+Click for multiple, or **Select All**)
2. Click **Delete Selected**
3. Confirm the deletion in the dialog
4. Snapshots are removed and a Teams notification is sent (if configured)

### Exporting Data

Click **Export CSV** in either view to save the current data. The export respects all active filters — what you see is what you export.

---

## Configuration

### Teams Webhook (Optional)

Snapshot deletion events can be sent to Microsoft Teams. Configure in one of two ways:

**Option A: Environment Variable (Recommended)**
```powershell
$env:HYPERV_TEAMS_WEBHOOK_URL = 'https://your-webhook-url-here'
```

**Option B: Config File**

Create a `config.json` in the script directory:
```json
{
    "TeamsWebhookUrl": "https://your-webhook-url-here"
}
```

### Log File

All operations are logged to `HyperV-Toolkit.log` in the script directory. Logs are automatically rotated when the file exceeds 10 MB, with the 5 most recent archives retained.

```
[2026-02-10 14:30:15] [INFO] Connecting to nodes: HyperV-01, HyperV-02
[2026-02-10 14:30:25] [SUCCESS] Successfully loaded 45 VMs and 128 snapshots
[2026-02-10 14:31:10] [WARNING] Teams notification skipped (no webhook URL configured)
```

### Data Files

| File | Purpose |
|:-----|:--------|
| `serverinfo.json` | Cached VM information for instant display |
| `snapshots.json` | Cached snapshot data |
| `favorites.json` | Persistent VM favorites |
| `nodes.json` | Connection history with usage tracking |
| `config.json` | Configuration (Teams webhook URL, etc.) |

---

## Architecture

```
HyperV-Manager.ps1                  # Entry point, event handlers, UI orchestration
Modules/
  Common.psm1                       # Logging, notifications, favorites, caching, config
  ServerManagement.psm1              # VM information gathering (local + remote)
  SnapshotManagement.psm1            # Snapshot retrieval and deletion
  UIComponents.psm1                  # Windows Forms UI components, dark theme
```

### Design Principles

- **Modular** — Each module handles a single concern
- **Async** — Background runspaces prevent UI freezing during data collection
- **Progressive** — Data loads and displays incrementally as VMs are processed
- **Cached** — JSON-based caching enables instant display while refreshing in background
- **Responsive** — Fully resizable window with anchored layout
- **Secure** — No hardcoded secrets; webhook URLs loaded from environment or config

---

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

### Guest OS Shows "N/A"
Guest OS detection requires Hyper-V Integration Services to be running inside the VM. Ensure the VM has integration components installed and the KVP Exchange Data service is running.

### Cached Data is Stale
Click **Refresh** in any view to force a fresh data collection. Cache age is displayed in the status bar when loading from cache.

---

## Upcoming Features

Here's what's planned for future releases:

| Feature | Status |
|:--------|:-------|
| **VM Power Control** — Start, stop, pause, and resume VMs directly from the UI | Planned |
| **Scheduled Snapshot Cleanup** — Auto-delete snapshots older than a configured threshold | Planned |
| **Resource Alerts** — Configurable thresholds for memory, CPU, and disk usage warnings | Planned |
| **Snapshot Creation** — Create new snapshots with custom names from the UI | Planned |
| **Multi-User Audit Trail** — Windows Event Log integration for enterprise compliance | Planned |
| **RBAC Support** — Role-based permissions for view-only vs. admin users | In Research |
| **Dark/Light Theme Toggle** — Switch between dark and light themes | In Research |
| **IPv6 Support** — Display IPv6 addresses alongside IPv4 | Planned |
| **VM Disk Resize** — Expand virtual hard drives from the management interface | In Research |
| **Export to PDF** — Generate formatted PDF reports of VM and snapshot data | Planned |
| **Custom Dashboard** — Configurable overview cards with key metrics at a glance | In Research |
| **Bulk VM Operations** — Start/stop multiple VMs at once with confirmation | Planned |

---

## Version History

| Version | Changes |
|:--------|:--------|
| **4.0** | Renamed to HyperV Toolkit. Fixed remote OS/disk detection in progressive mode. Config-based webhook URL (removed hardcoded secrets). Log rotation. Responsive UI layout with proper anchoring. Search debouncing. Input validation. Improved error handling. Local snapshot deletion fallback for cached objects. |
| 3.1 | Fixed pipeline expression error in scrollbar event handlers |
| 3.0 | Modern dark theme UI, custom scrollbars, connection history |
| 2.1 | Search & filtering, CSV export, favorites system |
| 2.0 | Server management module, modular architecture |
| 1.0 | Initial snapshot management tool |

---

## Contributing

Contributions are welcome! If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push to your branch and open a Pull Request

Please ensure your changes follow the existing code style and include appropriate error handling.

---

## License

This project is provided as-is for managing Hyper-V environments. Use at your own risk.

---

<div align="center">
  <sub>Built with PowerShell and Windows Forms</sub>
</div>
