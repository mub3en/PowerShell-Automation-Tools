--Database File Location Summary
IF EXISTS( Select 1 FROM sys.objects WHERE name = 'getDBFileLocationInfo' AND type = 'P') 
DROP PROCEDURE [dbo].[getDBFileLocationInfo]
GO

CREATE PROCEDURE [dbo].[getDBFileLocationInfo] AS 
BEGIN
    SELECT
        distinct DB_NAME(database_id)   AS [Database name],
            type_desc                   AS [Database file Type],
            name                        AS [File name],
            physical_name               AS [File Location],
            state_desc                  AS [Database file status],
            SIZE                        AS [Initial Size (MB)],
            max_size                    AS [Maximum Size (MB)]
    FROM
        sys.master_files masterfiles
    WHERE
        DB_NAME(database_id) NOT IN ('master', 'msdb', 'tempdb', 'model')
END
GO
    
EXEC dbo.getDBFileLocationInfo
