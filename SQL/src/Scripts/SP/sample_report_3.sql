--Database Size and Other Detail
IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'getDBSizeandOtherInfo' AND type = 'P')
DROP PROCEDURE [dbo].[getDBSizeandOtherInfo]
GO

CREATE PROCEDURE [dbo].[getDBSizeandOtherInfo] AS 
BEGIN
    SELECT
        distinct dbs.NAME                   AS [Database Name],
        dbs.state_desc                      AS [Database Status],
        CONVERT(DATETIME, dbs.create_date)  AS [Database create date],
        dbs.compatibility_level             AS [Compatibility Level],
        dbs.recovery_model_desc             AS [Database Recovery Model],
        dbs.delayed_durability_desc         AS [Delayed Durability],
        dbs.containment_desc                AS [Containtment],
        CONVERT(
            NVARCHAR, (Sum(Cast(masterfiles.size AS BIGINT)) * 8 / 1024)
        )                                   AS [Database Size (MB)]
    FROM
        sys.master_files                    AS masterfiles
    INNER JOIN sys.databases AS dbs ON dbs.database_id = masterfiles.database_id
    WHERE
        dbs.database_id > 4 -- Skip system databases
    GROUP BY
        dbs.NAME,
        dbs.NAME,
        dbs.state_desc,
        dbs.compatibility_level,
        dbs.create_date,
        dbs.recovery_model_desc,
        dbs.delayed_durability_desc,
        dbs.containment_desc,
        dbs.default_language_name,
        dbs.default_fulltext_language_name
    ORDER BY
        dbs.NAME
    END
GO
    
EXEC dbo.getDBSizeandOtherInfo
