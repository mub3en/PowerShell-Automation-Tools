--Disk Report Summary
IF EXISTS( SELECT 1 FROM sys.objects WHERE ame = 'getDiskSpaceInfo' and type = 'P' ) 
DROP PROCEDURE [dbo].[getDiskSpaceInfo]
GO

CREATE PROCEDURE [dbo].[getDiskSpaceInfo] AS 
BEGIN
    SELECT
        DISTINCT volume_mount_point                                         AS[Mount Point],
                file_system_type                                            AS [File System],
                logical_volume_name                                         AS [Logical Drive],
                CONVERT(Numeric(10, 2), total_bytes / 1048576 / 1024)       AS [Total Space (GB)],
                Convert(Numeric(10, 2), available_bytes / 1048576 / 1024)   AS [Available Space (GB)],
                CAST(
                        CAST(available_bytes AS FLOAT) / CAST(total_bytes AS FLOAT) AS DECIMAL(18, 2)
                ) * 100                                                     AS [Available Space In %]
    FROM
        sys.master_files
    CROSS APPLY sys.dm_os_volume_stats(database_id, file_id) 
    
    --SELECT distinct
    --   volume_mount_point,
    --   logical_volume_name ,
    --   Convert(VARCHAR,CONVERT(Numeric(10,2),total_bytes/1048576/1024)),
    --   Convert(VARCHAR,Convert(Numeric(10,2),available_bytes/1048576/1024)),
    --   CONVERT(VARCHAR,CAST(CAST(available_bytes AS FLOAT)/ CAST(total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100)
    --FROM
    -- sys.master_files masterfiles
    --CROSS APPLY sys.dm_os_volume_stats(masterfiles.database_id, masterfiles.FILE_ID)
END
GO
    
EXEC dbo.getDiskSpaceInfo
