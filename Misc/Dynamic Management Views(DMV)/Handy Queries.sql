--------------------------------------------------------------------------------
--------------------- Related to the Extended Events ---------------------------
--------------------------------------------------------------------------------
/*Run the query below to obtain a list of the available events, actions, and targets*/
SELECT
  obj.object_type,
  pkg.name AS [package_name],
  obj.name AS [object_name],
  obj.description AS [description]
FROM sys.dm_xe_objects  AS obj
  INNER JOIN sys.dm_xe_packages AS pkg  ON pkg.guid = obj.package_guid
WHERE obj.object_type in ('action',  'event',  'target')
ORDER BY obj.object_type,
  pkg.name,
  obj.name;

/*Create an extended events session using T-SQL*/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name='test_session')
  DROP EVENT session test_session ON SERVER;
GO

CREATE EVENT SESSION test_session
ON SERVER
  ADD EVENT sqlos.async_io_requested,
  ADD EVENT sqlserver.lock_acquired
  ADD TARGET package0.etw_classic_sync_target (SET default_etw_session_logfile_path = N'C:\<DIRECTORY>\<FILE_NAME>.etl' )
  WITH (MAX_MEMORY=4MB, MAX_EVENT_SIZE=4MB);
GO

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  
--------------------------------------------------------------------------------
-------------------- Create Database Users on an Azure SQL DB ------------------
--------------------------------------------------------------------------------

--Ref Article: https://techcommunity.microsoft.com/t5/azure-database-support-blog/create-sql-login-and-sql-user-on-your-azure-sql-db/ba-p/368813
  
/*For the purposes of Azure SQL Database, it is considered a best practice to 
create users at the scope of the user database, and not in the master database.*/
CREATE USER [dba@AzureDomain.com] FROM EXTERNAL PROVIDER;
GO

/*If logins are created at the instance level in SQL Server, a user should then be 
created within the database, which maps the user to the server-based login */
USE Master
GO
 
CREATE LOGIN demo WITH PASSWORD = 'Pa55.w.rd'
GO
 
USE Database_Name
GO
 
CREATE USER demo FROM LOGIN demo
GO

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-------------------- Create Database Users on an Azure SQL DB ------------------
--------------------------------------------------------------------------------


--Refernce Article: https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-details-transact-sql?view=sql-server-ver16

--Genral Article: https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/system-dynamic-management-views?view=sql-server-ver16
SELECT
    CONVERT (varchar(30), getdate(), 126) AS runtime,
    mig.index_group_handle,
    mid.index_handle,
    CONVERT (decimal (28, 1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) ) AS improvement_measure,
    'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + 
        CONVERT (varchar, mid.index_handle) + ' ON ' + mid.statement 
        + ' (' + ISNULL (mid.equality_columns, '') 
        + CASE
            WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ','
            ELSE ''
        END + ISNULL (mid.inequality_columns, '') + ')' + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.*,
    mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28, 1),migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
