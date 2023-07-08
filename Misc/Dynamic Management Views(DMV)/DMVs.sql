/*
Ref Article: https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=azuresqldb-current
*/

/*
Dynamic management views and functions return internal, implementation-specific state data. 
Their schemas and the data they return may change in future releases of SQL Server. 
Therefore, dynamic management views and functions in future releases may not be compatible 
with the dynamic management views and functions in this release. For example, in future 
releases of SQL Server, Microsoft may augment the definition of any dynamic management view 
by adding columns to the end of the column list. 

WARNING: We recommend against using the syntax SELECT * FROM <dynamic_management_view_name> in production code 
because the number of columns returned might change and break your application.
*/

--------------------------------------------------------------------------
--------------------------------- INDEXES --------------------------------
--------------------------------------------------------------------------

--Returns information about indexes that are missing in a specific index group, except for spatial indexes.
select * from sys.dm_db_missing_index_groups
--Returns summary information about groups of missing indexes, excluding spatial indexes.
select * from sys.dm_db_missing_index_group_stats
--ONLY SQL Server 2019 (15.x) and  Azure SQL Database and Azure SQL Managed Instance
--Returns information about queries that needed a missing index from groups of missing indexes, excluding spatial indexes. More than one query may be returned per missing index group. 
--One missing index group may have several queries that needed the same index.
select * from sys.dm_db_missing_index_group_stats_query 

--Returns information about queries that needed a missing index from groups of missing indexes, excluding spatial indexes. More than one query may be returned per missing index group. 
--One missing index group may have several queries that needed the same index.
select * from sys.dm_db_missing_index_group_stats_query 

--Returns detailed information about missing indexes, excluding spatial indexes.
select * from sys.dm_db_missing_index_details 

--Returns size and fragmentation information for the data and indexes of the specified table or view in SQL Server.
--sys.dm_db_index_physical_stats (
--    { database_id | NULL | 0 | DEFAULT }
--  , { object_id | NULL | 0 | DEFAULT }
--  , { index_id | NULL | 0 | -1 | DEFAULT }
--  , { partition_number | NULL | 0 | DEFAULT }
--  , { mode | NULL | DEFAULT }
--)
SELECT * FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, NULL)

--Returns current lower-level I/O, locking, latching, and access method activity for each partition of a table or index in the database.
--Memory-optimized indexes do not appear in this DMV. 
--  sys.dm_db_index_operational_stats (    
--     { database_id | NULL | 0 | DEFAULT }    
--   , { object_id | NULL | 0 | DEFAULT }    
--   , { index_id | 0 | NULL | -1 | DEFAULT }    
--   , { partition_number | NULL | 0 | DEFAULT }    
-- ) 
SELECT * FROM sys.dm_db_index_operational_stats (NULL, NULL, NULL, NULL)

--Returns counts of different types of index operations and the time each type of operation was last performed.
SELECT * FROM sys.dm_db_index_operational_stats 
 


--------------------------------------------------------------------------
------------------------------- CACHED PLANS -----------------------------
--------------------------------------------------------------------------

--sys.dm_exec_query_plan_stats --> Returns the equivalent of the last known actual execution plan for a previously cached query plan.
--sys.dm_exec_cached_plans --> Returns a row for each query plan that is cached by SQL Server for faster query execution. You can use this dynamic management view to find cached query plans, cached query text, the amount of memory taken by cached plans, and the reuse count of the cached plans.
--sys.dm_exec_sql_text --> Returns the text of the SQL batch that is identified by the specified sql_handle.
--sys.dm_exec_query_stats --> Returns aggregate performance statistics for cached query plans in SQL Server.

SELECT * FROM sys.dm_exec_cached_plans;
GO

SELECT *
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan_stats(plan_handle) AS qps;
GO

SELECT sql_handle FROM sys.dm_exec_requests WHERE sql_handle is not null
--SELECT sql_handle FROM sys.dm_exec_requests WHERE session_id = 59  -- modify this value with your actual spid

--Returns the text of the SQL batch that is identified by the specified sql_handle.
SELECT * FROM sys.dm_exec_sql_text(0x02000000501F6E2DEA5E72AE4F886C250F2D66F661CC6EBB0000000000000000000000000000000000000000) -- modify this value with your actual sql_handle

SELECT t.*
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t


--Returns aggregate performance statistics for cached query plans in SQL Server. 
--The view contains one row per query statement within the cached plan, and the lifetime of the rows are tied to the plan itself. 
--When a plan is removed from the cache, the corresponding rows are eliminated from this view.
SELECT * FROM sys.dm_exec_query_stats


--------------------------------------------------------------------------
------------------------------ RESOURCE GOVERNER -------------------------
--------------------------------------------------------------------------

--Only works with Azure SQL Database
--Returns actual configuration and capacity settings used by resource governance mechanisms in the current database or elastic pool.
SELECT * FROM sys.dm_user_db_resource_governance

--Returns information about the current resource pool state, the current configuration of resource pools, and resource pool statistics.
SELECT * FROM sys.dm_resource_governor_resource_pools

--Returns workload group statistics and the current in-memory configuration of the workload group
SELECT * FROM sys.dm_resource_governor_workload_groups 

--This only returns 3 fields: 
--classifier_function_id, is_reconfiguration_pending, and max_outstanding_io_per_volume. 
--It cannot be used to retrieve the actual configuration and capacity settings.
SELECT * FROM sys.dm_resource_governor_configuration

--------------------------------------------------------------------------
------------------------------ Requests/Resource Monitoring -----------------------
--------------------------------------------------------------------------

--Returns information about each request that is executing in SQL Server.
SELECT * FROM sys.dm_exec_requests 


----ONLY works with Azure SQL DB
--Returns CPU usage and storage data for an Azure SQL Database. 
--The data is collected and aggregated within five-minute intervals.
--The data returned includes CPU usage, storage size change, and database SKU modification. Idle databases with no changes may not have rows for every five-minute interval. 
--Historical data is retained for approximately 14 days.
SELECT * FROM sys.resource_stats
--Returns resource usage statistics for all the elastic pools in a SQL Database server. 
--For each elastic pool, there is one row for each 15 second reporting window (four rows per minute). 
--This includes CPU, IO, Log, storage consumption and concurrent request/session utilization by all databases in the pool. 
--This data is retained for 14 days.
SELECT * FROM sys.elastic_pool_resource_stats

----ONLY works with Azure Managed Instance 
--Returns CPU usage, IO, and storage data for Azure SQL Managed Instance. 
--The data is collected and aggregated within five-minute intervals. 
--There is one row for every 15 seconds reporting. The data returned includes CPU usage, storage size, IO utilization, and SKU. 
--Historical data is retained for approximately 14 days.
SELECT * FROM sys.server_resource_stats


----ONLY works with Azure SQL Database and Azure Managed Instance 
--Provides hourly summary of resource usage data for user databases in the current server. 
--Historical data is retained for 90 days.
--For each user database, there is one row for every hour in continuous fashion. Even if the database was idle during that hour, there is one row, and the usage_in_seconds value for that database will be 0. 
--Storage usage and SKU information is rolled up for the hour appropriately.
SELECT * FROM sys.resource_usage

--Returns CPU, I/O, and memory consumption for an Azure SQL Database database or an Azure SQL Managed Instance. 
--One row exists for every 15 seconds, even if there is no activity. 
--Historical data is maintained for approximately one hour.
SELECT * FROM sys.dm_db_resource_stats






--------------------------------------------------------------------------
--------------------------- Connections Monitoring -----------------------
--------------------------------------------------------------------------

--Returns information about the connections established to this instance of SQL Server and the details of each connection. Returns server wide connection information for SQL Server. 
--Returns current database connection information for SQL Database.
SELECT * FROM sys.dm_exec_connections


--------------------------------------------------------------------------
------------------------------ Job Monitoring ----------------------------
--------------------------------------------------------------------------
--A job object is a Windows construct that implements CPU, memory, and IO resource governance at the operating system level.
SELECT * FROM sys.dm_os_job_object


--------------------------------------------------------------------------
--------------------------- Page level Monitoring ------------------------
--------------------------------------------------------------------------
--Returns the number of pages allocated and deallocated by each session for the database. 
--Internal objects are only in tempdb.
SELECT * FROM sys.dm_db_session_space_usage

--Returns the same information by task.
SELECT * FROM sys.dm_db_task_space_usage




--------------------------------------------------------------------------
--------------------------- Page level Monitoring ------------------------
--------------------------------------------------------------------------

--Returns information about all the waits encountered by threads that executed. 
--You can use this aggregated view to diagnose performance issues with SQL Server and also with specific queries and batches.
SELECT * FROM sys.dm_os_wait_stats

--Provides similar information by session.
SELECT * FROM sys.dm_exec_session_wait_stats 

--ONLY works with Azure SQL Database and Azure SQL Managed Instance
--Returns information about all the waits encountered by threads that executed during operation. 
--You can use this aggregated view to diagnose performance issues with Azure SQL Database and also with specific queries and batches.
SELECT * FROM sys.dm_db_wait_stats



--------------------------------------------------------------------------
--------------------------- Transactions Monitoring ----------------------
--------------------------------------------------------------------------

--Returns information about transactions for the instance of SQL Server
SELECT * FROM sys.dm_tran_active_transactions
--Returns correlation information for associated transactions and sessions.
SELECT * FROM sys.dm_tran_session_transactions

SELECT * FROM sys.dm_tran_current_snapshot

SELECT * FROM sys.dm_tran_current_transaction

--Returns information about transactions at the database level
SELECT * FROM sys.dm_tran_database_transactions

--Returns information about currently active lock manager resources in SQL Server. 
--Each row represents a currently active request to the lock manager for a lock that has been granted or is waiting to be granted.
SELECT * FROM sys.dm_tran_locks

--Returns information about unresolved, aborted transactions on the SQL Server instance.
 SELECT * FROM sys.dm_tran_aborted_transactions


--------------------------------------------------------------------------
------------------------ SQL Server Tuning -------------------------------
--------------------------------------------------------------------------

--Returns detailed information about automatic tuning recommendations.
SELECT * FROM sys.dm_db_tuning_recommendations

--Returns the automatic tuning mode for this database. Refer to ALTER DATABASE SET AUTOMATIC_TUNING (Transact-SQL) for available options.
SELECT * FROM sys.database_automatic_tuning_mode

--Returns the automatic tuning options for this database.
SELECT * FROM sys.database_automatic_tuning_options



--------------------------------------------------------------------------
---------------- Query Store catalog views -------------------------------
--------------------------------------------------------------------------

--Applies to:  SQL Server 2016 (13.x) and later,  Azure SQL Database,  Azure SQL Managed Instance, Azure Synapse Analytics

--Returns the Query Store options for this database
SELECT * FROM sys.database_query_store_options 


--Contains information about each execution plan associated with a query

SELECT * FROM sys.query_store_plan 


--Contains information about the query and its associated overall aggregated runtime execution statistics.
SELECT * FROM sys.query_store_query


--Contains the Transact-SQL text and the SQL handle of the query.
SELECT * FROM sys.query_store_query_text 
