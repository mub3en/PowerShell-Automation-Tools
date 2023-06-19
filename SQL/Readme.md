
# PowerShell Database Script Execution

This PowerShell script allows you to execute SQL scripts against a SQL Server database and save the results in CSV files. It provides error handling for various database connection and execution issues. The script requires administrative privileges to run successfully.

## Prerequisites

Before running this script, ensure that you have met the following requirements:

- PowerShell version 5.1 or above.
- SQL Server Management Studio or SQL Server command-line tools installed.
- Access to the target SQL Server database.

## Dependencies

The dependencies modules are saved inside /src/Modules
For the latest modules you can refer to:
- [SQL Server](https://www.powershellgallery.com/packages/SqlServer/22.1.1) 
- [Requirements](https://www.powershellgallery.com/packages/Requirements/2.3.6)

## Getting Started

1. Clone or download the script files to your local machine.
2. Open a PowerShell terminal and navigate to the script's directory.

## Components

The script retrieves the following information components:

| Script Name | Description |
| :--- | :--- |
| [Get information on SQL Server in a report.](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/SQL/Get_SQL_Server_info.ps1) | A set of cmdlets functions that support actions such as getting information on SQL Server using all GET functions defined by [SQL Server](https://www.powershellgallery.com/packages/SqlServer/22.1.1)  modules.|
| [SQL authentication and Custom CSV Files.](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/SQL/Execute_SQL_and_Save_Results_in_FlatFiles.ps1) | Authenticates SQL user and execute scripts against the database. The results will then be saved in CSV files. |
| [SQL authentication and Custom HTML Reports](https://github.com/mub3en/PowerShell-Automation-Tools/tree/master/SQL/Execute_SQL_SPs_and_Build_HTML_Reports.ps1) | Authenticates SQL user and execute Stored Procedures against the database. The results will then be saved HTML formatted table. |

## Usage
1. Run the script by executing the following command: .\{SCRIPT_NAME}.ps1.
2. Enter the required information prompted by the script:
    - SQL Server Name: The name or IP address of the SQL Server.
    - SQL Instance Name (optional): The name of the SQL Server instance. Press Enter if empty.
    - SQL Database Name: The name of the target database.
    - SQL Login: Enter the credentials for accessing the database.
3. The script will iterate through the SQL script files located in the "Scripts" directory.
4. Each script will be executed against the specified SQL Server and database.
5. The results will then be saved in related directory.
5. If any errors occur during the execution, appropriate error messages will be displayed and logged in the "errors" directory.


## Exit Codes
The script uses the following exit codes to indicate the result of the execution:

- `1` Database Connectivity Test Failed
- `2` Database Login Failed
- `3` Database Connection Failed
- `4` Database Unknown Exception
- `5` Database Settings Not Defined
- `6` Launched Non-Elevated
- `7` Database Name Not Found
- `8` Unknown Exception


## Error Handling

The script includes error handling for different scenarios, such as database connection failures, login failures, and unexpected exceptions. Error messages will be displayed to provide insights into the encountered issues. In case of errors, a timestamped error log file will be created in the "errors" directory for further analysis.

Please note that this script assumes basic knowledge of SQL Server and PowerShell scripting. It's recommended to review and customize the script according to your specific requirements before running it in a production environment.