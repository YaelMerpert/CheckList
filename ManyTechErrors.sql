DECLARE @From DATETIME = DATEADD( hh , -1 , GETDATE() )
DECLARE @To DATETIME =GETDATE() 

-- mTERR
select MethodName,InsertDate INS,StackTrace,Parameters,* 
from CustomsLog_Pilot.Infrastructure.General_ExceptionLog 
WHERE InsertDate between @From and @To
AND MethodName<>'ErrorTraceListener'
AND MethodName<>'AllowedErrorTraceListener'
AND StackTrace LIKE '%sql%'
ORDER BY INS DESC

--TO
EXECUTE Maintenance.[_Admin_].[usp_Maintenance_GetTimeOutInfo] 
		@AlertTimeStart = @From
		, @AlertTimeEnd = @To
--		, @ObjectName = N''					   -- nvarchar(255)
--		, @AVG = 1							   -- bit
--		, @ExecuteInfo = 1					   -- bit


---Who is active
SELECT TOP 100 WIAM.InsertDate
			 , WIAM.start_time
			 , WIAM.blocking_session_id
			 , WIAM.session_id
			 , WIAM.cpu_time
			 , (WIAM.total_elapsed_time - WIAM.cpu_time) wait_time
			 , WIAM.total_elapsed_time
			 , WIAM.CPUUsage
			 , WIAM.command
			 , WIAM.wait_type
			 , WIAM.wait_resource
			 , WIAM.objectid
			 , OBJECT_NAME(WIAM.objectid , DB_ID(WIAM.DBName)) AS [objectname]
			 , WIAM.text
			 , WIAM.estimated_completion_time
			 , WIAM.logical_reads
			 , WIAM.reads
			 , WIAM.writes
			 , WIAM.status
			 , WIAM.open_transaction_count
			 , WIAM.transaction_isolation_level
			 , WIAM.nest_level
			 , WIAM.current_tasks_count
			 , WIAM.runnable_tasks_count
			 , WIAM.active_workers_count
			 , WIAM.current_workers_count
			 , WIAM.required_memory_kb
			 , WIAM.granted_memory_kb
			 , WIAM.requested_memory_kb
			 , WIAM.dop
FROM Maintenance._Admin_.WhoIsActive_LightMonitor AS WIAM (NOLOCK)
WHERE WIAM.InsertDate BETWEEN @From AND @To
AND WIAM.command NOT IN  ('XTP_OFFLINE_CKPT')
ORDER by wait_time desc 
OPTION (RECOMPILE);
