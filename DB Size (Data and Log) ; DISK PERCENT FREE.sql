

WITH fs
  AS
   (SELECT database_id,type , (size * 8.0 / 1024 / 1000) AS size FROM sys.master_files)
SELECT name
	 , (  SELECT SUM ( CAST(size AS DECIMAL(14, 4)))  FROM fs WHERE type = 0 AND fs.database_id = db.database_id  ) DataFileSizeGB
	 , (  SELECT SUM ( CAST(size AS DECIMAL(14, 4)))  FROM fs WHERE type = 1 AND fs.database_id = db.database_id  ) LogFileSizeGB
FROM sys.databases db
--WHERE name LIKE '%Customs_Test%';
ORDER BY DataFileSizeGB DESC 


--DISK PERCENT FREE
SELECT
distinct
 vs.volume_mount_point
	, CAST(CAST(( (  vs.total_bytes / 1024.0 ) / 1024.0 / 1024.0) AS NUMERIC(8,2)) AS NVARCHAR(10))+' GB' AS total_GB
 	 , CAST(CAST(( (   vs.available_bytes / 1024.0 ) / 1024.0 / 1024.0 ) AS NUMERIC(8,2)) AS NVARCHAR(10))+' GB'  AS available_GB 
	 , (CAST( (CAST((CAST(( (   vs.available_bytes / 1024.0 ) / 1024.0 / 1024.0 ) AS float) / CAST(( (  vs.total_bytes / 1024.0 ) / 1024.0 / 1024.0) AS FLOAT ) * 100 )AS int )) AS NVARCHAR(8))+'%')  AS Percent_Free
FROM sys.master_files AS f
	 CROSS APPLY sys.dm_os_volume_stats ( f.database_id, f.file_id ) vs
ORDER BY 1 

