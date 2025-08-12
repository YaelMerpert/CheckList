



-- DISK PERCENT FREE
SELECT
distinct
 vs.volume_mount_point
	, CAST(CAST(( (  vs.total_bytes / 1024.0 ) / 1024.0 / 1024.0) AS NUMERIC(8,2)) AS NVARCHAR(10))+' GB' AS total_GB
 	 , CAST(CAST(( (   vs.available_bytes / 1024.0 ) / 1024.0 / 1024.0 ) AS NUMERIC(8,2)) AS NVARCHAR(10))+' GB'  AS available_GB 
	 , (CAST( (CAST((CAST(( (   vs.available_bytes / 1024.0 ) / 1024.0 / 1024.0 ) AS float) / CAST(( (  vs.total_bytes / 1024.0 ) / 1024.0 / 1024.0) AS FLOAT ) * 100 )AS int )) AS NVARCHAR(8))+'%')  AS Percent_Free
FROM sys.master_files AS f
	 CROSS APPLY sys.dm_os_volume_stats ( f.database_id, f.file_id ) vs;






/*#######################################################################################################*/




DROP TABLE IF EXISTS #MasterFiles
CREATE TABLE #MasterFiles
	(
		database_id INT
	  , file_id INT
	  , type_desc NVARCHAR(50)
	  , name NVARCHAR(255)
	  , physical_name NVARCHAR(255)
	  , size BIGINT
	);
INSERT INTO #MasterFiles
	(
		database_id
	  , file_id
	  , type_desc
	  , name
	  , physical_name
	  , size
	)
SELECT database_id
	 , file_id
	 , type_desc
	 , name
	 , physical_name
	 , size
FROM sys.master_files;



SELECT  d.name
,type_desc
, sum (size ) AS size
, CAST(CAST(( ( (SUM (size)*8) / 1024.0 ) / 1024.0) AS NUMERIC(12,4)) AS NVARCHAR(10))+' GB' AS total_GB
, LEFT (  physical_name , 3)
FROM #MasterFiles
INNER JOIN sys.databases D ON D.database_id = #MasterFiles.database_id
GROUP BY d.name
	   , type_desc
	   , LEFT (  physical_name , 3)
ORDER BY d.name , type_desc DESC 


--DECLARE @Seconds INT = 0,
--@StartSampleTime DATETIMEOFFSET = SYSDATETIMEOFFSET();


-- SELECT
--        1 AS Pass,
--        CASE @Seconds WHEN 0 THEN @StartSampleTime ELSE SYSDATETIMEOFFSET() END AS SampleTime,
--        mf.[database_id],
--        mf.[file_id],
--        DB_NAME(vfs.database_id) AS [db_name],
--        mf.name + N' [' + mf.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + N']' AS file_logical_name ,
--        CAST(( ( vfs.size_on_disk_bytes / 1024.0 ) / 1024.0 ) AS INT) AS size_on_disk_mb ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.io_stall_read_ms END ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.num_of_reads END ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.[num_of_bytes_read] END ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.io_stall_write_ms END ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.num_of_writes END ,
--        CASE @Seconds WHEN 0 THEN 0 ELSE vfs.[num_of_bytes_written] END ,
--        mf.physical_name,
--        mf.type_desc
--    FROM sys.dm_io_virtual_file_stats (NULL, NULL) AS vfs
--    INNER JOIN #MasterFiles AS mf ON vfs.file_id = mf.file_id
--        AND vfs.database_id = mf.database_id
--    WHERE vfs.num_of_reads > 0
--        OR vfs.num_of_writes > 0;




/*#######################################################################################################*/
