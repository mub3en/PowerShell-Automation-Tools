--Database File Location Summary

If exists(Select 1 from sys.objects where name = 'getDBFileLocationInfo' and type = 'P')
DROP PROCEDURE [dbo].[getDBFileLocationInfo]
GO
CREATE PROCEDURE [dbo].[getDBFileLocationInfo]
AS
BEGIN
SELECT distinct
   DB_NAME(database_id) [Database name],
   type_desc [Database file Type],
   name [File name],
   physical_name [File Location],
   state_desc [Database file status],
   SIZE [Initial Size (MB)],
   max_size [Maximum Size (MB)]
FROM sys.master_files masterfiles WHERE DB_NAME(database_id)
NOT IN
('master','msdb','tempdb','model')


END
GO

exec dbo.getDBFileLocationInfo