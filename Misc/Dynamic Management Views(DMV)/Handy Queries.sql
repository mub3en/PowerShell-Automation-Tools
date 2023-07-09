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


--------------------------------------------------------------------------------
-------- Find all backups and create Restore statemnets dynamically ------------
--------------------------------------------------------------------------------

WITH BackupHist
AS
(
        SELECT
                s.server_name
            ,   d.name AS database_name
            ,   STUFF(( SELECT  ''', DISK = ''' + physical_device_name
                    FROM    msdb.dbo.backupmediafamily
                    WHERE   media_set_id = s.media_set_id
                    ORDER BY family_sequence_number
                    FOR XML PATH('')),
                1 ,
                3 ,
                '') + '''' AS physical_device_name
            ,   (   SELECT  TOP 1
                        CASE device_type
                            WHEN 2 THEN 'Disk'
                            WHEN 102 THEN 'Backup Device (Disk)'
                            WHEN 5 THEN 'Tape'
                            WHEN 105 THEN 'Backup Device (Tape)'
                            WHEN 7 THEN 'Virtual Device'
                        END AS device_type
                    FROM    msdb.dbo.backupmediafamily
                    WHERE   media_set_id = s.media_set_id) AS device_type
            ,   CAST (s.backup_size / 1048576.0 AS FLOAT) AS backup_size_mb
            ,   CAST (s.compressed_backup_size / 1048576.0 AS FLOAT) AS compressed_backup_size_mb
            ,   s.backup_start_date
            ,   s.first_lsn
            ,   s.last_lsn
            ,   s.checkpoint_lsn
            ,   s.backup_finish_date
            ,   s.database_backup_lsn
            ,   s.is_copy_only
            ,   CASE s.[type]
                    WHEN 'D' THEN 'Database (Full)'
                    WHEN 'I' THEN 'Database (Differential)'
                    WHEN 'L' THEN 'Transaction Log'
                    WHEN 'F' THEN 'File or Filegroup (Full)'
                    WHEN 'G' THEN 'File or Filegroup (DIfferential)'
                    WHEN 'P' THEN 'Partial (Full)'
                    WHEN 'Q' THEN 'Partial (Differential)'
                END AS backup_type
            ,   s.recovery_model
        FROM    msdb.dbo.backupset s RIGHT OUTER JOIN sys.databases d
                ON s.database_name = d.name
                AND s.recovery_model = d.recovery_model_desc
        COLLATE SQL_Latin1_General_CP1_CI_AS
), BackupHistFullIterations AS
(
    SELECT
            server_name
        ,   database_name
        ,   backup_finish_date
        ,   backup_type
        ,   database_backup_lsn
        ,   is_copy_only
        ,   first_lsn
        ,   last_lsn
        ,   checkpoint_lsn
        ,   physical_device_name
        ,   ROW_NUMBER() OVER (PARTITION BY database_name ORDER BY backup_finish_date DESC) AS BackupIteration
    FROM    BackupHist
    WHERE   backup_type = 'Database (Full)'
), BackupHistDiffIterations AS
(
    SELECT 
            server_name
        ,   database_name
        ,   backup_finish_date
        ,   backup_type
        ,   database_backup_lsn
        ,   is_copy_only
        ,   first_lsn
        ,   last_lsn
        ,   checkpoint_lsn
        ,   physical_device_name
        ,   ROW_NUMBER() OVER (PARTITION BY database_name ORDER BY backup_finish_date DESC) AS BackupIteration
    FROM    BackupHist
    WHERE   backup_type = 'Database (Differential)'
), BackupHistFullDiffRestores AS
(
        SELECT  *
            ,   MAX(last_lsn) OVER (PARTITION BY base.database_name ORDER BY backup_finish_date DESC) AS recent_last_lsn
            ,   ROW_NUMBER() OVER (PARTITION BY base.database_name ORDER BY backup_finish_date DESC) AS recent_bak_num
        FROM (
                SELECT  *
                FROM    BackupHistFullIterations
                WHERE   BackupIteration = 1 -- Show the most recent iteration

                UNION ALL

                -- Get most recent Differential based on Most Recent Full Backup if exists and most recent full is NOT a COPY-ONLY
                SELECT  *
                FROM    BackupHistDiffIterations d
                WHERE   d.BackupIteration = 1
                    AND d.database_backup_lsn = (   SELECT MAX(checkpoint_lsn)
                                                FROM BackupHistFullIterations
                                                WHERE BackupIteration = 1
                                                    AND database_name = d.database_name
                                                )
            ) base
)
SELECT
            server_name
        ,   database_name
        ,   backup_finish_date
        ,   backup_type
        ,   first_lsn
        ,   last_lsn
        ,   checkpoint_lsn
        ,   is_copy_only
        ,   CASE backup_type WHEN 'Database (Full)' THEN 'RESTORE DATABASE [' + database_name + '] FROM  ' + physical_device_name + ' WITH  FILE = 1, NORECOVERY, NOUNLOAD, REPLACE, STATS = 5'
                WHEN 'Database (Differential)' THEN 'RESTORE DATABASE [' + database_name + '] FROM  ' + physical_device_name + ' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 5'
                WHEN 'Transaction Log' THEN 'RESTORE LOG [' + database_name + '] FROM  ' + physical_device_name + ' WITH  FILE = 1, NORECOVERY, NOUNLOAD, STATS = 5'
                ELSE ''
            END AS RestoreStatement
FROM (
    SELECT  fdr.server_name
        ,   fdr.database_name
        ,   fdr.backup_finish_date
        ,   fdr.backup_type
        ,   fdr.physical_device_name
        ,   fdr.first_lsn
        ,   fdr.last_lsn
        ,   fdr.checkpoint_lsn
        ,   fdr.database_backup_lsn
        ,   fdr.is_copy_only
    FROM    BackupHistFullDiffRestores fdr

    UNION ALL

    SELECT  bhlr.server_name
        ,   bhlr.database_name
        ,   bhlr.backup_finish_date
        ,   bhlr.backup_type
        ,   bhlr.physical_device_name
        ,   bhlr.first_lsn
        ,   bhlr.last_lsn
        ,   bhlr.checkpoint_lsn
        ,   bhlr.database_backup_lsn
        ,   bhlr.is_copy_only
    FROM    BackupHistFullDiffRestores bhfdr 
            INNER JOIN BackupHist bhlr
                ON bhfdr.database_name = bhlr.database_name
                AND bhlr.last_lsn >= bhfdr.recent_last_lsn
                AND bhfdr.recent_bak_num = 1
    WHERE   bhlr.backup_type = 'Transaction Log'
) restore_cmd
ORDER BY 1, 2, 6




----OR---

-- Assign the database name to variable below
DECLARE @db_name VARCHAR(100)
SELECT @db_name = 'AdventureWorks2016'
-- query
SELECT TOP (30) s.database_name
,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
,s.backup_start_date
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,CASE s.[type] WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
WHEN 'L'
THEN 'Transaction Log'
END AS BackupType
,s.server_name
,s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = @db_name
ORDER BY backup_start_date DESC
,backup_finish_date
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
