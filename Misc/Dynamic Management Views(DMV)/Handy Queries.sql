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

--------------------------------------------------------------------------------
---------------------------- Table partitioning --------------------------------
--------------------------------------------------------------------------------
/*
There are four main steps required when defining a table partition:

1- The filegroups creation, which defines the files involved when the partitions are created.
2- The partition function creation, which defines the partition rules based on the specified column.
3- The partition scheme creation, which defines the filegroup of each partition.
4- The table to be partitioned.
*/

-- Partition function
CREATE PARTITION FUNCTION PartitionByMonth (datetime2)
    AS RANGE RIGHT
    -- The boundary values defined is the first day of each month, where the table will be partitioned into 13 partitions
    FOR VALUES ('20210101', '20210201', '20210301',
      '20210401', '20210501', '20210601', '20210701',
      '20210801', '20210901', '20211001', '20211101', 
      '20212101');
 
-- The partition scheme below will use the partition function created above, and assign each partition to a specific filegroup.
CREATE PARTITION SCHEME PartitionByMonthSch
    AS PARTITION PartitionByMonth
    TO (FILEGROUP1, FILEGROUP2, FILEGROUP3, FILEGROUP4,
        FILEGROUP5, FILEGROUP6, FILEGROUP7, FILEGROUP8,
        FILEGROUP9, FILEGROUP10, FILEGROUP11, FILEGROUP12);
 
-- Creates a partitioned table called Order that applies PartitionByMonthSch partition scheme to partition the OrderDate column  
CREATE TABLE Order ([Id] int PRIMARY KEY, OrderDate datetime2)  
    ON PartitionByMonthSch (OrderDate) ;  
GO

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


  
--------------------------------------------------------------------------------
------------------ General SQL Server & Database information -------------------
--------------------------------------------------------------------------------

--Ref Article: https://www.sqlservercentral.com/articles/building-a-database-dashboard-with-ssrs
-- this can be a quick/good report via SSRS
  
USE master 
GO 
SELECT name 'Server Name' , product 'Product Name' ,data_source 'Data Source Name',s.modify_date 'Modified Date', 
CASE WHEN is_linked =1 THEN 'Lineked Sever' WHEN is_linked=0 THEN 'Local Server' END 'Server Type' 
FROM sys.servers s 


SELECT      
 Convert(varchar,SERVERPROPERTY('ServerName')) AS ServerName     
 ,Convert(varchar,isnull(SERVERPROPERTY('InstanceName'), 'Default')) AS [SQLServer InstanceName]     
 ,Convert(varchar,SUBSTRING(@@VERSION,0,CHARINDEX('(',@@VERSION)-1)) as [SQLServer Version]     
 ,Convert(varchar,SERVERPROPERTY('EDITION')) AS [SQLServer Edition]    
  ,Convert(varchar,SERVERPROPERTY('InstanceDefaultDataPath')) AS [Default DataPath]     
 ,Convert(varchar,SERVERPROPERTY('InstanceDefaultLogPath')) AS [DEFAULT LogPath] 
 ,Convert(varchar,iif(SERVERPROPERTY('IsIntegratedSecurityOnly') = 0, 'Windows and SQL Server Authentication', 'Windows Authentication')) AS [Authentication Type]     
 ,cpu_count AS [Total Processor], 
 round(physical_memory_kb / 1024.0 / 1024.0, 2) AS [Physical Memory_GB]     
 ,sqlserver_start_time AS [LastStartTime], 
 (select count(name) from sys.databases where database_id>4) as 'Count of Databases',     
 (select count(name) from msdb..sysjobs where enabled=1) as 'Count of Jobs',     
 (SELECT  count(1) FROM    msdb.dbo.sysjobhistory h          INNER JOIN msdb.dbo.sysjobs j     ON h.job_id = j.job_id  INNER JOIN msdb.dbo.sysjobsteps s              ON j.job_id = s.job_id  AND h.step_id = s.step_id     
AND h.run_date > CONVERT(int     , CONVERT(varchar(10), DATEADD(DAY, -7, GETDATE()), 112)) and run_status = 0) 'Count of failed SQL Job'    
FROM sys.dm_os_sys_info  ,sys.dm_os_windows_info  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
------- Transfer logins and passwords between instances of SQL Server ----------
--------------------------------------------------------------------------------

--Ref: https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/security/transfer-logins-passwords-between-instances


USE [master]
  GO
  IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
  GO
  CREATE PROCEDURE [dbo].[sp_hexadecimal]
  (
      @binvalue varbinary(256),
      @hexvalue varchar (514) OUTPUT
  )
  AS
  BEGIN
      DECLARE @charvalue varchar (514)
      DECLARE @i int
      DECLARE @length int
      DECLARE @hexstring char(16)
      SELECT @charvalue = '0x'
      SELECT @i = 1
      SELECT @length = DATALENGTH (@binvalue)
      SELECT @hexstring = '0123456789ABCDEF'

      WHILE (@i <= @length)
      BEGIN
            DECLARE @tempint int
            DECLARE @firstint int
            DECLARE @secondint int

            SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
            SELECT @firstint = FLOOR(@tempint/16)
            SELECT @secondint = @tempint - (@firstint*16)
            SELECT @charvalue = @charvalue + SUBSTRING(@hexstring, @firstint+1, 1) + SUBSTRING(@hexstring, @secondint+1, 1)

            SELECT @i = @i + 1
      END 
      SELECT @hexvalue = @charvalue
  END
  go
  IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
  GO
  CREATE PROCEDURE [dbo].[sp_help_revlogin]   
  (
      @login_name sysname = NULL 
  )
  AS
  BEGIN
      DECLARE @name                     SYSNAME
      DECLARE @type                     VARCHAR (1)
      DECLARE @hasaccess                INT
      DECLARE @denylogin                INT
      DECLARE @is_disabled              INT
      DECLARE @PWD_varbinary            VARBINARY (256)
      DECLARE @PWD_string               VARCHAR (514)
      DECLARE @SID_varbinary            VARBINARY (85)
      DECLARE @SID_string               VARCHAR (514)
      DECLARE @tmpstr                   VARCHAR (1024)
      DECLARE @is_policy_checked        VARCHAR (3)
      DECLARE @is_expiration_checked    VARCHAR (3)
      Declare @Prefix                   VARCHAR(255)
      DECLARE @defaultdb                SYSNAME
      DECLARE @defaultlanguage          SYSNAME     
      DECLARE @tmpstrRole               VARCHAR (1024)

  IF (@login_name IS NULL)
  BEGIN
      DECLARE login_curs CURSOR 
      FOR 
          SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin, p.default_language_name  
          FROM  sys.server_principals p 
          LEFT JOIN sys.syslogins     l ON ( l.name = p.name ) 
          WHERE p.type IN ( 'S', 'G', 'U' ) 
            AND p.name <> 'sa'
          ORDER BY p.name
  END
  ELSE
          DECLARE login_curs CURSOR 
          FOR 
              SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin, p.default_language_name  
              FROM  sys.server_principals p 
              LEFT JOIN sys.syslogins        l ON ( l.name = p.name ) 
              WHERE p.type IN ( 'S', 'G', 'U' ) 
                AND p.name = @login_name
              ORDER BY p.name

          OPEN login_curs 
          FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin, @defaultlanguage 
          IF (@@fetch_status = -1)
          BEGIN
                PRINT 'No login(s) found.'
                CLOSE login_curs
                DEALLOCATE login_curs
                RETURN -1
          END

          SET @tmpstr = '/* sp_help_revlogin script '
          PRINT @tmpstr

          SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'

          PRINT @tmpstr
          PRINT ''

          WHILE (@@fetch_status <> -1)
          BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
                  PRINT ''

                  SET @tmpstr = '-- Login: ' + @name

                  PRINT @tmpstr

                  SET @tmpstr='IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''+@name+''')
                  BEGIN'
                  Print @tmpstr 

                  IF (@type IN ( 'G', 'U'))
                  BEGIN -- NT authenticated account/group 
                    SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']' + ', DEFAULT_LANGUAGE = [' + @defaultlanguage + ']'
                  END
                  ELSE 
                  BEGIN -- SQL Server authentication
                          -- obtain password and sid
                          SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )

                          EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
                          EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT

                          -- obtain password policy state
                          SELECT @is_policy_checked     = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END 
                          FROM sys.sql_logins 
                          WHERE name = @name

                          SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END 
                          FROM sys.sql_logins 
                          WHERE name = @name

                          SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' 
                                          + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']' + ', DEFAULT_LANGUAGE = [' + @defaultlanguage + ']'

                          IF ( @is_policy_checked IS NOT NULL )
                          BEGIN
                            SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
                          END

                          IF ( @is_expiration_checked IS NOT NULL )
                          BEGIN
                            SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
                          END
          END

          IF (@denylogin = 1)
          BEGIN -- login is denied access
              SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
          END
          ELSE IF (@hasaccess = 0)
          BEGIN -- login exists but does not have access
              SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
          END
          IF (@is_disabled = 1)
          BEGIN -- login is disabled
              SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
          END 

          SET @Prefix = '
          EXEC master.dbo.sp_addsrvrolemember @loginame='''

          SET @tmpstrRole=''

          SELECT @tmpstrRole = @tmpstrRole
              + CASE WHEN sysadmin        = 1 THEN @Prefix + [LoginName] + ''', @rolename=''sysadmin'''        ELSE '' END
              + CASE WHEN securityadmin   = 1 THEN @Prefix + [LoginName] + ''', @rolename=''securityadmin'''   ELSE '' END
              + CASE WHEN serveradmin     = 1 THEN @Prefix + [LoginName] + ''', @rolename=''serveradmin'''     ELSE '' END
              + CASE WHEN setupadmin      = 1 THEN @Prefix + [LoginName] + ''', @rolename=''setupadmin'''      ELSE '' END
              + CASE WHEN processadmin    = 1 THEN @Prefix + [LoginName] + ''', @rolename=''processadmin'''    ELSE '' END
              + CASE WHEN diskadmin       = 1 THEN @Prefix + [LoginName] + ''', @rolename=''diskadmin'''       ELSE '' END
              + CASE WHEN dbcreator       = 1 THEN @Prefix + [LoginName] + ''', @rolename=''dbcreator'''       ELSE '' END
              + CASE WHEN bulkadmin       = 1 THEN @Prefix + [LoginName] + ''', @rolename=''bulkadmin'''       ELSE '' END
            FROM (
                      SELECT CONVERT(VARCHAR(100),SUSER_SNAME(sid)) AS [LoginName],
                              sysadmin,
                              securityadmin,
                              serveradmin,
                              setupadmin,
                              processadmin,
                              diskadmin,
                              dbcreator,
                              bulkadmin
                      FROM sys.syslogins
                      WHERE (       sysadmin<>0
                              OR    securityadmin<>0
                              OR    serveradmin<>0
                              OR    setupadmin <>0
                              OR    processadmin <>0
                              OR    diskadmin<>0
                              OR    dbcreator<>0
                              OR    bulkadmin<>0
                          ) 
                          AND name=@name 
                ) L 

              PRINT @tmpstr
              PRINT @tmpstrRole
              PRINT 'END'
          END 
          FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin, @defaultlanguage 
      END
      CLOSE login_curs
      DEALLOCATE login_curs
      RETURN 0
  END



--Call SP
EXEC sp_help_revlogin

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-------------- Understand and resolve SQL Server blocking problems -------------
--------------------------------------------------------------------------------

/*
Ref article: https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/understand-resolve-blocking

sys.dm_tran_active_transactions 
The sys.dm_tran_active_transactions DMV contains data about open transactions that 
can be joined to other DMVs for a complete picture of transactions awaiting commit or rollback. 
Use the following query to return information on open transactions, joined to other 
DMVs including sys.dm_tran_session_transactions. Consider a transaction's current state,
transaction_begin_time, and other situational data to evaluate whether it could be a source of blocking.
*/

SELECT tst.session_id, [database_name] = db_name(s.database_id)
, tat.transaction_begin_time
, transaction_duration_s = datediff(s, tat.transaction_begin_time, sysdatetime()) 
, transaction_type = CASE tat.transaction_type  WHEN 1 THEN 'Read/write transaction'
                                                WHEN 2 THEN 'Read-only transaction'
                                                WHEN 3 THEN 'System transaction'
                                                WHEN 4 THEN 'Distributed transaction' END
, input_buffer = ib.event_info, tat.transaction_uow     
, transaction_state  = CASE tat.transaction_state    
            WHEN 0 THEN 'The transaction has not been completely initialized yet.'
            WHEN 1 THEN 'The transaction has been initialized but has not started.'
            WHEN 2 THEN 'The transaction is active - has not been committed or rolled back.'
            WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
            WHEN 4 THEN 'The commit process has been initiated on the distributed transaction.'
            WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
            WHEN 6 THEN 'The transaction has been committed.'
            WHEN 7 THEN 'The transaction is being rolled back.'
            WHEN 8 THEN 'The transaction has been rolled back.' END 
, transaction_name = tat.name, request_status = r.status
, tst.is_user_transaction, tst.is_local
, session_open_transaction_count = tst.open_transaction_count  
, s.host_name, s.program_name, s.client_interface_name, s.login_name, s.is_user_process
FROM sys.dm_tran_active_transactions tat 
INNER JOIN sys.dm_tran_session_transactions tst  on tat.transaction_id = tst.transaction_id
INNER JOIN Sys.dm_exec_sessions s on s.session_id = tst.session_id 
LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
CROSS APPLY sys.dm_exec_input_buffer(s.session_id, null) AS ib;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


