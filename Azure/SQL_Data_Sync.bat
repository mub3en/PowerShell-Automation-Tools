@REM https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-download?view=sql-server-ver15#windows-net-framework
@REM Default directory for windows:  C:\Program Files\Microsoft SQL Server\160\DAC\bin
@REM cd C:\Program Files\Microsoft SQL Server\160\DAC\bin

@REM To IMPORT:
sqlpackage.exe /a:Import /TargetServerName:SERVER_NAME /TargetDatabaseName:DATABASE_NAME /TargetUser:USERNAME /TargetPassword:PASSWORD /SourceFile:BACPAC_DIRECTORY

@REM To EXPORT:
sqlpackage.exe /a:Import /SourceServerName:SERVER_NAME /SourcetDatabaseName:DATABASE_NAME /SourceUser:USERNAME /SourcetPassword:PASSWORD /TargetFile:BACPAC_DIRECTORY