# Hyper-V Snapshot Management Tool

A PowerShell-based GUI tool for managing Hyper-V virtual machine snapshots across one or multiple Hyper-V hosts.

## Features

- **Multi-Host Support**: Connect to one or multiple Hyper-V nodes simultaneously
- **VM Discovery**: Automatically discovers all VMs on connected hosts
- **Snapshot Visibility**: View all VM snapshots with creation dates and age calculation
- **Easy Deletion**: Select and delete multiple snapshots with a single click
- **Age Tracking**: Shows snapshot age in days, hours, and minutes
- **Statistics**: Displays total snapshots and count of snapshots older than 7 days
- **User-Friendly Interface**: Clean, intuitive Windows Forms GUI

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

### Viewing VMs and Snapshots

- **Left Panel**: Lists all discovered VMs with their state (Running, Stopped, etc.) and host
- **Right Panel**: DataGridView showing all snapshots with:
  - Host node name
  - VM name
  - Snapshot name
  - Creation time
  - Age (human-readable)
  - Age in days (numeric)

### Deleting Snapshots

1. Select one or more snapshots in the grid (Ctrl+Click or Shift+Click for multiple)
2. Use **Select All** or **Deselect All** buttons for bulk operations
3. Click **Delete Selected** (red button)
4. Confirm the deletion when prompted
5. The tool will delete the snapshots and refresh the list automatically

### Refreshing Data

Click the **Refresh** button to reload all snapshot information without reconnecting to the hosts.

## UI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Hyper-V Nodes: [____________] (comma-separated)  [Connect] [Refresh] │
│ Status: [Status messages displayed here]                       │
├──────────────┬──────────────────────────────────────────────────┤
│ VMs:         │ Snapshots:                                       │
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
- **Hyper-V Cmdlets Used**:
  - `Get-VM`
  - `Get-VMSnapshot`
  - `Remove-VMSnapshot`

## License

This tool is provided as-is for managing Hyper-V environments.

## Author

Created by Claude (2026-01-09)
