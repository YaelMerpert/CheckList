--Expensive queries
SELECT TOP 10 creation_time, 
              last_execution_time, 
              total_worker_time, 
              total_elapsed_time, 
              SUBSTRING(st.text, qs.statement_start_offset / 2 + 1, (CASE statement_end_offset
                                                                         WHEN-1
                                                                         THEN DATALENGTH(st.text)
                                                                         ELSE qs.statement_end_offset
                                                                     END - qs.statement_start_offset) / 2 + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
     CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY total_worker_time DESC;

-- mTERR

DECLARE @From DATETIME = DATEADD( hh , -5 , GETDATE() )
DECLARE @To DATETIME =GETDATE() 
select MethodName,InsertDate INS,StackTrace,Parameters,* 
from CustomsLog_Pilot.Infrastructure.General_ExceptionLog 
WHERE InsertDate between @From and @To
AND MethodName<>'ErrorTraceListener'
AND MethodName<>'AllowedErrorTraceListener'
AND StackTrace LIKE '%sql%'
ORDER BY INS DESC