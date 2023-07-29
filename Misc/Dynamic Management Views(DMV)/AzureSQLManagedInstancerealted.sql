/*
Ref article: https://learn.microsoft.com/en-us/azure/azure-sql/database/high-cpu-diagnose-troubleshoot?view=azuresql-db&viewFallbackFrom=azuresql-mi

Diagnose and troubleshoot high CPU on Azure SQL Database

*/

--Identify vCore count with Transact-SQL
SELECT 
    COUNT(*) as vCores
FROM sys.dm_os_schedulers
WHERE status = N'VISIBLE ONLINE';
GO
