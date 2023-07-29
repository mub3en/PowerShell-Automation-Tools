/*
Ref article: https://learn.microsoft.com/en-us/azure/azure-sql/database/high-cpu-diagnose-troubleshoot?view=azuresql-db

Diagnose and troubleshoot high CPU on Azure SQL Database

*/

------------------------------------------
--Identify vCore count with Transact-SQL--
------------------------------------------
SELECT 
    COUNT(*) as vCores
FROM sys.dm_os_schedulers
WHERE status = N'VISIBLE ONLINE';
GO

--------------------------------------------------------
--Identify currently running queries with Transact-SQL--
--------------------------------------------------------
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

----------------------------------------------
--Review CPU usage metrics for the last hour--
----------------------------------------------
SELECT
    end_time,
    avg_cpu_percent,
    avg_instance_cpu_percent
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC; 
GO

------------------------------------------------ 
--Query the top recent 15 queries by CPU usage--
------------------------------------------------
WITH AggregatedCPU AS 
    (SELECT
        q.query_hash, 
        SUM(count_executions * avg_cpu_time / 1000.0) AS total_cpu_ms, 
        SUM(count_executions * avg_cpu_time / 1000.0)/ SUM(count_executions) AS avg_cpu_ms, 
        MAX(rs.max_cpu_time / 1000.00) AS max_cpu_ms, 
        MAX(max_logical_io_reads) max_logical_reads, 
        COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans, 
        COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids, 
        SUM(CASE WHEN rs.execution_type_desc='Aborted' THEN count_executions ELSE 0 END) AS aborted_execution_count, 
        SUM(CASE WHEN rs.execution_type_desc='Regular' THEN count_executions ELSE 0 END) AS regular_execution_count, 
        SUM(CASE WHEN rs.execution_type_desc='Exception' THEN count_executions ELSE 0 END) AS exception_execution_count, 
        SUM(count_executions) AS total_executions, 
        MIN(qt.query_sql_text) AS sampled_query_text
    FROM sys.query_store_query_text AS qt
    JOIN sys.query_store_query AS q ON qt.query_text_id=q.query_text_id
    JOIN sys.query_store_plan AS p ON q.query_id=p.query_id
    JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id=p.plan_id
    JOIN sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id=rs.runtime_stats_interval_id
    WHERE 
            rs.execution_type_desc IN ('Regular', 'Aborted', 'Exception') AND 
        rsi.start_time>=DATEADD(HOUR, -2, GETUTCDATE())
     GROUP BY q.query_hash), 
OrderedCPU AS 
    (SELECT *, 
    ROW_NUMBER() OVER (ORDER BY total_cpu_ms DESC, query_hash ASC) AS RN
    FROM AggregatedCPU)
SELECT *
FROM OrderedCPU AS OD
WHERE OD.RN<=15
ORDER BY total_cpu_ms DESC;
GO

------------------------------------------------------------
--Query the most frequently compiled queries by query hash--
------------------------------------------------------------
SELECT TOP (20)
    query_hash,
    MIN(initial_compile_start_time) as initial_compile_start_time,
    MAX(last_compile_start_time) as last_compile_start_time,
    CASE WHEN DATEDIFF(mi,MIN(initial_compile_start_time), MAX(last_compile_start_time)) > 0
        THEN 1.* SUM(count_compiles) / DATEDIFF(mi,MIN(initial_compile_start_time), 
            MAX(last_compile_start_time)) 
        ELSE 0 
        END as avg_compiles_minute,
    SUM(count_compiles) as count_compiles
FROM sys.query_store_query AS q
GROUP BY query_hash
ORDER BY count_compiles DESC;
GO

----------------------------------------------------------------
--Identify the CPU usage and query plan for a given query hash--
----------------------------------------------------------------
declare @query_hash binary(8);

SET @query_hash = 0x6557BE7936AA2E91;

with query_ids as (
    SELECT
        q.query_hash,
        q.query_id,
        p.query_plan_hash,
        SUM(qrs.count_executions) * AVG(qrs.avg_cpu_time)/1000. as total_cpu_time_ms,
        SUM(qrs.count_executions) AS sum_executions,
        AVG(qrs.avg_cpu_time)/1000. AS avg_cpu_time_ms
    FROM sys.query_store_query q
    JOIN sys.query_store_plan p on q.query_id=p.query_id
    JOIN sys.query_store_runtime_stats qrs on p.plan_id = qrs.plan_id
    WHERE q.query_hash = @query_hash
    GROUP BY q.query_id, q.query_hash, p.query_plan_hash)
SELECT qid.*,
    qt.query_sql_text,
    p.count_compiles,
    TRY_CAST(p.query_plan as XML) as query_plan
FROM query_ids as qid
JOIN sys.query_store_query AS q ON qid.query_id=q.query_id
JOIN sys.query_store_query_text AS qt on q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan AS p ON qid.query_id=p.query_id and qid.query_plan_hash=p.query_plan_hash
ORDER BY total_cpu_time_ms DESC;
GO

------------------------------------------------------------
--Reduce CPU usage by tuning the max degree of parallelism--
------------------------------------------------------------
SELECT 
    name, 
    value, 
    value_for_secondary, 
    is_value_default 
FROM sys.database_scoped_configurations
WHERE name=N'MAXDOP';
GO
