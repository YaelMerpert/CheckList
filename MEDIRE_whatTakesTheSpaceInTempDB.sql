/*
TempDB Space Utilization Check
==============================
Author: Eitan Blumin | https://www.madeiradata.com
Date: 2022-05-03
Description:
	Based on scripts available at the following resources:
	https://www.sqlshack.com/monitor-sql-server-tempdb-database/
	https://www.mssqltips.com/sqlservertip/4356/track-sql-server-tempdb-space-usage/
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

-- File Stats Overview
SELECT
	instance_name			    AS [DatabaseName]
      , [Data File(s) Size (KB)] / 1024	    AS [Data file (MB)]
      , [LOG File(s) Size (KB)] / 1024	    AS [Log file (MB)]
      , [Log File(s) Used Size (KB)] / 1024 AS [Log file space used (MB)]
      , (
		SELECT SUM(size) / 128 FROM tempdb.sys.database_files
	)				    AS [Total database size (MB)]
FROM
(
	SELECT	*
	FROM	sys.dm_os_performance_counters
	WHERE
		counter_name IN
		(
			'Data File(s) Size (KB)', 'Log File(s) Size (KB)', 'Log File(s) Used Size (KB)'
		)
		AND instance_name = 'tempdb'
) AS A
PIVOT
(
	MAX(cntr_value)
	FOR counter_name IN
	(
		[Data File(s) Size (KB)], [LOG File(s) Size (KB)], [Log File(s) Used Size (KB)]
	)
) AS B;
GO

-- Object Types Overview
SELECT	(SUM(unallocated_extent_page_count) / 128)   AS [Free space (MB)]
      , SUM(internal_object_reserved_page_count) * 8 AS [Internal objects (KB)]
      , SUM(user_object_reserved_page_count) * 8     AS [User objects (KB)]
      , SUM(version_store_reserved_page_count) * 8   AS [Version store (KB)]
FROM	tempdb.sys.dm_db_file_space_usage
--database_id '2' represents tempdb
WHERE	database_id = 2;
GO

-- Temp Table Space Utilization Stats
SELECT
	tb.name			    AS [Temporary table name]
      , stt.row_count		    AS [Number of rows]
      , stt.used_page_count * 8	    AS [Used space (KB)]
      , stt.reserved_page_count * 8 AS [Reserved space (KB)]
FROM
	tempdb.sys.partitions		      AS prt
INNER	JOIN tempdb.sys.dm_db_partition_stats AS stt ON prt.partition_id = stt.partition_id
							     AND prt.partition_number = stt.partition_number
INNER	JOIN tempdb.sys.tables		      AS tb ON stt.object_id = tb.object_id
ORDER BY [Reserved space (KB)] DESC;
GO

-- Session Usage of TempDB
SELECT
	COALESCE(T1.session_id, T2.session_id)							     [session_id]
      , T1.request_id
      , COALESCE(T1.database_id, T2.database_id)						     [database_id]
      , COALESCE(T1.[Total Allocation User Objects], 0) + T2.[Total Allocation User Objects]	     [Total Allocation User Objects]
      , COALESCE(T1.[Net Allocation User Objects], 0) + T2.[Net Allocation User Objects]	     [Net Allocation User Objects]
      , COALESCE(T1.[Total Allocation Internal Objects], 0) + T2.[Total Allocation Internal Objects] [Total Allocation Internal Objects]
      , COALESCE(T1.[Net Allocation Internal Objects], 0) + T2.[Net Allocation Internal Objects]     [Net Allocation Internal Objects]
      , COALESCE(T1.[Total Allocation], 0) + T2.[Total Allocation]				     [Total Allocation]
      , COALESCE(T1.[Net Allocation], 0) + T2.[Net Allocation]					     [Net Allocation]
      , COALESCE(T1.[Query Text], T2.[Query Text])						     [Query Text]
FROM
(
	SELECT
		TS.session_id
	      , TS.request_id
	      , TS.database_id
	      , CAST(TS.user_objects_alloc_page_count / 128 AS decimal(15, 2))						      [Total Allocation User Objects]
	      , CAST((TS.user_objects_alloc_page_count - TS.user_objects_dealloc_page_count) / 128 AS decimal(15, 2))	      [Net Allocation User Objects]
	      , CAST(TS.internal_objects_alloc_page_count / 128 AS decimal(15, 2))					      [Total Allocation Internal Objects]
	      , CAST((TS.internal_objects_alloc_page_count - TS.internal_objects_dealloc_page_count) / 128 AS decimal(15, 2)) [Net Allocation Internal Objects]
	      , CAST((TS.user_objects_alloc_page_count + internal_objects_alloc_page_count) / 128 AS decimal(15, 2))	      [Total Allocation]
	      , CAST((TS.user_objects_alloc_page_count + TS.internal_objects_alloc_page_count
		      - TS.internal_objects_dealloc_page_count - TS.user_objects_dealloc_page_count
		     ) / 128 AS decimal(15, 2))										      [Net Allocation]
	      , ISNULL(T.text, inpbuf.event_info)									      [Query Text]
	FROM
		sys.dm_db_task_space_usage		  TS
	INNER	JOIN sys.dm_exec_requests		  ER ON ER.request_id = TS.request_id AND ER.session_id = TS.session_id
	OUTER	APPLY sys.dm_exec_sql_text(ER.sql_handle) T
	OUTER	APPLY sys.dm_exec_input_buffer(ER.session_id, NULL) inpbuf

) T1
RIGHT	JOIN
(
	SELECT
		SS.session_id
	      , SS.database_id
	      , CAST(SS.user_objects_alloc_page_count / 128 AS decimal(15, 2))						      [Total Allocation User Objects]
	      , CAST((SS.user_objects_alloc_page_count - SS.user_objects_dealloc_page_count) / 128 AS decimal(15, 2))	      [Net Allocation User Objects]
	      , CAST(SS.internal_objects_alloc_page_count / 128 AS decimal(15, 2))					      [Total Allocation Internal Objects]
	      , CAST((SS.internal_objects_alloc_page_count - SS.internal_objects_dealloc_page_count) / 128 AS decimal(15, 2)) [Net Allocation Internal Objects]
	      , CAST((SS.user_objects_alloc_page_count + internal_objects_alloc_page_count) / 128 AS decimal(15, 2))	      [Total Allocation]
	      , CAST((SS.user_objects_alloc_page_count + SS.internal_objects_alloc_page_count
		      - SS.internal_objects_dealloc_page_count - SS.user_objects_dealloc_page_count
		     ) / 128 AS decimal(15, 2))										      [Net Allocation]
	      , ISNULL(T.text, inpbuf.event_info)									      [Query Text]
	FROM
		sys.dm_db_session_space_usage			      SS
	LEFT	JOIN sys.dm_exec_connections			      CN ON CN.session_id = SS.session_id
	OUTER	APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) T
	OUTER	APPLY sys.dm_exec_input_buffer(SS.session_id, NULL) inpbuf
) T2	ON T1.session_id = T2.session_id
ORDER BY
	[Total Allocation] DESC
      , [Total Allocation User Objects] DESC;
GO
--

--216		NULL	2	5526.00	0.00s	5048.00	2.00	10574.00	2.00
--1297		NULL	2	694.00	635.00	5687.00	-28.00	6381.00	606.00
--1549		NULL	2	2044.00	0.00	1865.00	5.00	3910.00	5.00
--150		NULL	2	467.00	0.00	8.00	8.00	475.00	9.00
--1211		NULL	2	297.00	256.00	43.00	0.00	341.00	255.00
--670		NULL	2	57.00	5.00	14.00	0.00	71.00	4.00


--SELECT session_id, host_name, program_name, original_login_name, host_process_id, status

--FROM sys.dm_exec_sessions

--WHERE session_id IN (670,216,1549)

--sp_who3

--670	NULL	2	4816.00	6.00	33352.00	-661.00	38168.00
--216	NULL	2	18618.00	0.00	17052.00	9.00	35670.00
--1549	NULL	2	6912.00	0.00	6934.00	19.00	13846.00
