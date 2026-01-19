# Hyper-V Server Management Tool

A comprehensive PowerShell-based GUI tool for managing Hyper-V servers and virtual machine snapshots across one or multiple Hyper-V hosts.

## Features

### Server Management
- **IP Address Discovery**: View all IP addresses assigned to VMs
- **Memory Monitoring**: Track memory allocation, usage, and available memory for each VM
- **Storage Information**: Monitor disk size and usage for VM virtual hard drives
- **CPU Information**: View processor count for each VM
- **VM State Tracking**: See current state of all VMs (Running, Stopped, etc.)

### Snapshot Management
- **Multi-Host Support**: Connect to one or multiple Hyper-V nodes simultaneously
- **VM Discovery**: Automatically discovers all VMs on connected hosts
- **Snapshot Visibility**: View all VM snapshots with creation dates and age calculation
- **Easy Deletion**: Select and delete multiple snapshots with a single click
- **Age Tracking**: Shows snapshot age in days, hours, and minutes
- **Statistics**: Displays total snapshots and count of snapshots older than 7 days

### Search & Filtering
- **Quick Search**: Real-time search boxes for VMs, snapshots, and server information
- **State Filtering**: Filter VMs by state (Running, Stopped, Paused, Saved)
- **Age Filtering**: Filter snapshots by age (7, 30, or 90 days)
- **Favorites Filter**: Show only favorite VMs with one click

### Data Management
- **Export to CSV**: Export server information and snapshot data to CSV files
- **Favorites System**: Mark VMs as favorites for quick access
- **Right-click Context Menu**: Add/remove favorites via context menu on server grid

### General Features
- **Modern UI**: Professional blue color scheme with custom title bar
- **Custom Title Bar**: Draggable title bar with minimize, maximize, and close buttons
- **Main Menu Interface**: Easy navigation between Server Management and Snapshot Management
- **Background Processing**: All operations run in background threads for non-blocking UI
- **Modular Architecture**: Organized code structure with separate modules for better performance
- **Logging**: Automatic logging of all operations to HyperV-ManagementTool.log
- **Teams Notifications**: Automatic Teams webhook notifications when snapshots are deleted
- **Responsive Design**: Clean, intuitive interface with hover effects and smooth transitions

## Requirements

- **Windows PowerShell 5.1 or later**
- **Hyper-V PowerShell Module** (included with Hyper-V role)
- **Administrator privileges** on the Hyper-V hosts
- **WinRM enabled** for remote host connections

## Installation

1. Clone or download this repository
2. Ensure you have the Hyper-V PowerShell module installed:
   ```powershell
   Get-Module -ListAvailable Hyper-V
   ```
3. If connecting to remote hosts, ensure WinRM is configured:
   ```powershell
   Enable-PSRemoting -Force
   ```

## Usage

### Starting the Tool

Run the PowerShell script with administrator privileges:

```powershell
.\main.ps1
```

### Connecting to Hyper-V Hosts

1. Enter one or more Hyper-V host names in the text box:
   - For local machine: `localhost` (default)
   - For single remote host: `HyperV-Server01`
   - For multiple hosts: `HyperV-Server01, HyperV-Server02, HyperV-Server03`

2. Click **Connect** to establish connections and retrieve VMs

3. Once connected, the main menu will display two options:
   - **Server Management** - View server information
   - **Snapshot Management** - Manage VM snapshots

### Using Server Management

1. Click **Server Management** from the main menu
2. The tool will gather detailed information about all VMs:
   - Node (Hyper-V host name)
   - VM Name
   - State (Running, Stopped, etc.)
   - IP Addresses (IPv4)
   - Memory Total (GB)
   - Memory Used (GB)
   - Memory Available (GB)
   - CPU Count
   - Disk Size (GB)
   - Disk Used (GB)
3. Click **Refresh** to update the information
4. Click **Back to Menu** to return to the main menu

### Using Snapshot Management

1. Click **Snapshot Management** from the main menu
2. **Left Panel**: Lists all discovered VMs with their state and host
3. **Right Panel**: DataGridView showing all snapshots with:
   - Host node name
   - VM name
   - Snapshot name
   - Creation time
   - Age (human-readable)
   - Age in days (numeric)

### Deleting Snapshots

1. From the Snapshot Management view, select one or more snapshots in the grid (Ctrl+Click or Shift+Click for multiple)
2. Use **Select All** or **Deselect All** buttons for bulk operations
3. Click **Delete Selected** (red button)
4. Confirm the deletion when prompted
5. The tool will delete the snapshots and refresh the list automatically

### Refreshing Data

Click the **Refresh** button in either Server Management or Snapshot Management to reload information without reconnecting to the hosts.

## UI Layout

### Main Menu (After Connection)
```
┌─────────────────────────────────────────────────────────────────┐
│ Hyper-V Nodes: [____________] (comma-separated)  [Connect] [Back to Menu] │
│ Status: Connected successfully to 2 node(s) - 45 VMs found     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│           Hyper-V Server Management Tool                        │
│           Connect to a Hyper-V node to begin                    │
│                                                                 │
│              ┌────────────────────────────┐                     │
│              │   Server Management        │                     │
│              └────────────────────────────┘                     │
│         View server information: IP addresses,                  │
│              memory, and storage                                │
│                                                                 │
│              ┌────────────────────────────┐                     │
│              │  Snapshot Management       │                     │
│              └────────────────────────────┘                     │
│            View and manage VM snapshots                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Server Management View
```
┌─────────────────────────────────────────────────────────────────┐
│ Hyper-V Nodes: [____________]  [Connect] [Back to Menu]        │
│ Status: Loaded information for 45 VMs                          │
├─────────────────────────────────────────────────────────────────┤
│ Server Management                             [Refresh]         │
│                                                                 │
│ ┌───────────────────────────────────────────────────────────┐  │
│ │ Node | VM | State | IPs | Memory | CPU | Disk | ...      │  │
│ │ ──────────────────────────────────────────────────────────│  │
│ │ Data rows showing server information...                   │  │
│ └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Snapshot Management View
```
┌─────────────────────────────────────────────────────────────────┐
│ Hyper-V Nodes: [____________]  [Connect] [Back to Menu]        │
│ Status: Loaded 128 snapshots from 45 VMs                       │
├──────────────┬──────────────────────────────────────────────────┤
│ VMs:         │ Snapshots:                          [Refresh]    │
│              │                                                  │
│ - VM1 [Run]  │ ┌──────────────────────────────────────────┐    │
│ - VM2 [Stop] │ │ Node | VM | Snapshot | Created | Age     │    │
│ - VM3 [Run]  │ │ ───────────────────────────────────────  │    │
│              │ │ Data rows...                              │    │
│              │ └──────────────────────────────────────────┘    │
│              │                                                  │
│              │ [Delete Selected] [Select All] [Deselect All]   │
│              │ Total: X snapshots | Older than 7 days: Y       │
└──────────────┴──────────────────────────────────────────────────┘
```

## Logging and Notifications

### Automatic Logging

The tool automatically logs all operations to a file named `HyperV-ManagementTool.log` in the same directory as the script.

**Logged Events:**
- Application start and shutdown
- Connection attempts to Hyper-V nodes
- VM and snapshot discovery
- Server information gathering
- Snapshot refresh operations
- Navigation between views
- Snapshot deletion (success and failures)
- Errors and warnings

**Log Format:**
```
[2026-01-19 14:30:15] [INFO] Hyper-V Server Management Tool started
[2026-01-19 14:30:20] [INFO] Connecting to nodes: HyperV-01, HyperV-02
[2026-01-19 14:30:25] [SUCCESS] Successfully loaded 45 VMs and 128 snapshots
[2026-01-19 14:30:30] [INFO] Navigating to Server Management
[2026-01-19 14:31:10] [SUCCESS] Successfully deleted snapshot 'Test-Snapshot' from VM 'WebServer01' on node 'HyperV-01'
```

### Teams Webhook Notifications

When snapshots are successfully deleted, the tool automatically sends a notification to Microsoft Teams via webhook.

**Notification Contents:**
- Number of snapshots deleted
- Details of each deleted snapshot (snapshot name, VM name, node)
- Number of failures (if any)
- Username and computer name of the person who performed the deletion

**Configuration:**
The Teams webhook URL is configured in the script at line 19. To change it, edit the `$script:TeamsWebhookUrl` variable:

```powershell
$script:TeamsWebhookUrl = 'YOUR_TEAMS_WEBHOOK_URL_HERE'
```

**Example Teams Message:**
```
Hyper-V Snapshots Deleted
Deleted Snapshots: 3

- Test-Snapshot from VM WebServer01 on node HyperV-01
- Old-Checkpoint from VM DBServer02 on node HyperV-02
- Backup-20250101 from VM AppServer03 on node HyperV-01

Executed by: AdminUser on MGMT-PC01
```

## Permissions

### Local Machine
- Must run PowerShell as Administrator

### Remote Hosts
- User must be in the Hyper-V Administrators group on the remote host
- Or be a Domain Administrator
- WinRM must be enabled and accessible

## Troubleshooting

### "Access Denied" errors
- Ensure you're running PowerShell as Administrator
- Verify you have permissions on the remote Hyper-V host
- Check that your user is in the "Hyper-V Administrators" group

### Cannot connect to remote host
- Verify WinRM is enabled: `Test-WSMan HOSTNAME`
- Check firewall rules allow WinRM (TCP 5985/5986)
- Ensure the remote host is accessible: `Test-Connection HOSTNAME`

### "Hyper-V module not found"
- Install Hyper-V PowerShell module:
  ```powershell
  Install-WindowsFeature -Name Hyper-V-PowerShell
  ```
  Or on Windows 10/11:
  ```powershell
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell
  ```

## Safety Features

- **Confirmation Dialog**: Always asks for confirmation before deleting snapshots
- **Cannot be undone warning**: Clearly indicates that deletion is permanent
- **Error Handling**: Gracefully handles connection failures and reports errors
- **Partial Success Reporting**: Shows how many snapshots succeeded/failed during batch deletion

## Technical Details

- **Framework**: Windows Forms (.NET)
- **Language**: PowerShell 5.1+
- **Architecture**: Modular design with separate modules for improved performance
- **Background Processing**: Uses PowerShell runspaces for non-blocking operations

### Modular Architecture

The tool is organized into separate modules for better maintainability and performance:

```
snapshottool/
├── main.ps1                    # Main entry point
└── Modules/
    ├── Common.psm1             # Logging, notifications, and utilities
    ├── ServerManagement.psm1   # Server information gathering functions
    ├── SnapshotManagement.psm1 # Snapshot operations
    └── UIComponents.psm1       # UI component creation functions
```

**Module Descriptions:**

- **Common.psm1**: Shared utilities including logging, Teams notifications, and status updates
- **ServerManagement.psm1**: Functions to gather VM information (IP addresses, memory, storage, CPU)
- **SnapshotManagement.psm1**: Functions to retrieve and delete VM snapshots
- **UIComponents.psm1**: Functions to create UI panels and controls

### Hyper-V Cmdlets Used
  - `Get-VM` - Retrieve virtual machines
  - `Get-VMSnapshot` - Retrieve VM snapshots
  - `Remove-VMSnapshot` - Delete snapshots
  - `Get-VMNetworkAdapter` - Get network adapter information for IP addresses
  - `Get-VMHardDiskDrive` - Get virtual disk information
  - `Get-VHD` - Get VHD/VHDX file information

## Performance

- All operations run in background PowerShell runspaces to prevent UI freezing
- Modular design allows for efficient code reuse
- Separate timers for different background operations
- Non-blocking UI ensures responsive user experience

## License

This tool is provided as-is for managing Hyper-V environments.

## Author

Created by Claude
- Version 1.0: 2026-01-09 - Initial snapshot management tool
- Version 2.0: 2026-01-19 - Added server management and modular architecture
- Version 2.1: 2026-01-19 - Modern UI, search & filtering, export to CSV, favorites system
