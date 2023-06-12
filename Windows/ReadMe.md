# PowerShell Hardware Information Tool

This PowerShell script gathers hardware information from a Windows system and displays it in a tabular format. It retrieves information about the system, processor, memory, disk, network adapter, and operating system.

## Usage

1. Open PowerShell.
2. Navigate to the directory where the script is located.
3. Run the script using the command: `.\SCRIPT_NAME.ps1`
4. The script will display in the console and saved to a text file.

## Components

The script retrieves the following information components:

| Script Name | Description |
| :--- | :--- |
| [Antivirus and Firewall Status](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/AV_Firewall_status.ps1) | Returns windows AntiVirus and Firewall status. |
| [Operating System Info](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/OS_info.ps1) | Returns Windows Operating System information. |
| [Server Hardware Info](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/Server_Hardware_info.ps1) | Returns server hardware information. |
| [Software Info](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/software_info.ps1) | Returns a list of the softwares installed on the server. |
| [Network Info](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/server_network_info.ps1) | Returns information of the network and related stats. |
| [Users and Groups Info](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/users_groups_info.ps1) | Returns a list of Users and Groups in active directory. |

## Output

The information is displayed in a tabular format in the PowerShell console. Additionally, the output is saved to a text file for future reference.

### Execute using a batch script
You can execute all `.ps1` scripts at once using [batch file](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/Windows/execute_ALL_Scripts.bat)

## Requirements

- Windows system with PowerShell.
- Administrative privileges or appropriate access permissions to retrieve hardware information.

