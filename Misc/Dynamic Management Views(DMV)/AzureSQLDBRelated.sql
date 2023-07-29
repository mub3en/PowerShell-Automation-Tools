/*
Ref article: https://learn.microsoft.com/en-us/azure/azure-sql/database/high-cpu-diagnose-troubleshoot?view=azuresql-db

Diagnose and troubleshoot high CPU on Azure SQL Database

*/

--Identify vCore count with Transact-SQL
SELECT 
    COUNT(*) as vCores
FROM sys.dm_os_schedulers
WHERE status = N'VISIBLE ONLINE';
GO

--Identify currently running queries with Transact-SQL
SELECT
    req.session_id,
    req.status,
    req.start_time,
    req.cpu_time AS 'cpu_time_ms',
    req.logical_reads,
    req.dop,
    s.login_name,
    s.host_name,
    s.program_name,
    object_name(st.objectid,st.dbid) 'ObjectName',
    REPLACE (REPLACE (SUBSTRING (st.text,(req.statement_start_offset/2) + 1,
        ((CASE req.statement_end_offset    WHEN -1    THEN DATALENGTH(st.text) 
        ELSE req.statement_end_offset END - req.statement_start_offset)/2) + 1),
        CHAR(10), ' '), CHAR(13), ' ') AS statement_text,
    qp.query_plan,
    qsx.query_plan as query_plan_with_in_flight_statistics
FROM sys.dm_exec_requests as req  
JOIN sys.dm_exec_sessions as s on req.session_id=s.session_id
CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) as st
OUTER APPLY sys.dm_exec_query_plan(req.plan_handle) as qp
OUTER APPLY sys.dm_exec_query_statistics_xml(req.session_id) as qsx
ORDER BY req.cpu_time desc;
GO
