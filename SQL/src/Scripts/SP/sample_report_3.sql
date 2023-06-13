--Database Size and Other Detail
If exists(Select 1 from sys.objects where name = 'getDBSizeandOtherInfo' and type = 'P')
DROP PROCEDURE [dbo].[getDBSizeandOtherInfo]
GO
CREATE PROCEDURE [dbo].[getDBSizeandOtherInfo]
AS
BEGIN
SELECT distinct
   dbs.NAME [Database Name],
   dbs.state_desc [Database Status],
   CONVERT(DATETIME, dbs.create_date) [Database create date],
   dbs.compatibility_level [Compatibility Level],
   dbs.recovery_model_desc [Database Recovery Model],
   dbs.delayed_durability_desc [Delayed Durability],
   dbs.containment_desc [Containtment],
   CONVERT(NVARCHAR,(Sum(Cast(masterfiles.size AS BIGINT)) * 8 / 1024)) [Database Size (MB)]
FROM   sys.master_files masterfiles
   INNER JOIN sys.databases dbs
           ON dbs.database_id = masterfiles.database_id
WHERE  dbs.database_id > 4 -- Skip system databases
GROUP  BY dbs.NAME,
      dbs.NAME,
      dbs.state_desc,
      dbs.compatibility_level,
      dbs.create_date,
      dbs.recovery_model_desc,
      dbs.delayed_durability_desc,
      dbs.containment_desc,
      dbs.default_language_name,
      dbs.default_fulltext_language_name
ORDER  BY dbs.NAME

END
GO

exec dbo.getDBSizeandOtherInfo