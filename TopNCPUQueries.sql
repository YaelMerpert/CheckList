DECLARE @sqlmajorver int;
DECLARE @sqlminorver int;
DECLARE @sqlbuild int;
SELECT @sqlmajorver =  CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff);
SELECT @sqlminorver = CONVERT(int, (@@microsoftversion / 0x10000) & 0xff);
SELECT @sqlbuild = CONVERT(int, @@microsoftversion & 0xffff);

IF @sqlmajorver >= 10
     BEGIN
		EXEC (';WITH QueryStats AS (
					SELECT TOP 10
								MIN(creation_time) AS creation_time,  
								MAX(last_execution_time) AS last_execution_time, 
								SUM(total_worker_time) AS total_worker_time,
								SUM(total_worker_time)/SUM(execution_count) AS [Avg_CPU_Time],
								SUM(execution_count) AS execution_count, 
								MIN(qs.statement_start_offset) as statement_start_offset,
								MIN(qs.statement_end_offset)  as statement_end_offset,
								MIN(qs.plan_handle) as plan_handle,
								query_hash, MIN(sql_handle) as sql_handle
							FROM 
								sys.dm_exec_query_stats AS qs
							GROUP BY query_hash
							ORDER BY 4 DESC		
					)
				SELECT 
					qs.creation_time,  
					qs.last_execution_time, 
					qs.total_worker_time,
					qs.[Avg_CPU_Time],
					qs.execution_count, 
					SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) 
								AS statement_text,
					db_name(tqp.dbid) as database_name,
					object_name(tqp.objectid, tqp.dbid) as object_name,
					query_hash
						FROM 
							QueryStats qs
							CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
							cross apply sys.dm_exec_text_query_plan( qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset ) as tqp')
	END
ELSE 
  IF @sqlmajorver = 9 AND @sqlbuild >= 3042
     BEGIN
		EXEC ('SELECT TOP 10 
			creation_time, 
			last_execution_time, 
			total_worker_time,
			total_worker_time/execution_count AS [Avg_CPU_Time],
			execution_count, 
			SUBSTRING(st.text, (qs.statement_start_offset/2) + 1, ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) 
				AS statement_text,
			db_name(tqp.dbid) as database_name,
			object_name(tqp.objectid, tqp.dbid) as object_name,
			''n/a'' as query_hash
		FROM 
			sys.dm_exec_query_stats as qs
			CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st
			cross apply sys.dm_exec_text_query_plan( qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset ) as tqp
		ORDER BY total_worker_time/execution_count DESC')
	END