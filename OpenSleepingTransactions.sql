SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF OBJECT_ID('tempdb..#SessionsWithLocks') IS NOT NULL DROP TABLE #SessionsWithLocks;
CREATE TABLE #SessionsWithLocks(request_session_id int PRIMARY KEY);
INSERT INTO #SessionsWithLocks
SELECT DISTINCT request_session_id
FROM sys.dm_tran_locks
WHERE resource_type = N'DATABASE'
AND request_mode = N'S'
AND request_status = N'GRANT'
AND request_owner_type = N'SHARED_TRANSACTION_WORKSPACE';


SELECT 
TxDesc = 'SPID ' + QUOTENAME(CAST(s.spid AS varchar(6))) + ' is sleeping since ' + QUOTENAME(CONVERT(VARCHAR(19), s.last_batch, 120))
+ ' with open transaction(s). hostname: ' + QUOTENAME(RTRIM(s.hostname)) + ', IP: ' + ISNULL(QUOTENAME(c.client_net_address), '(unknown)')
+ ', program: ' + QUOTENAME(RTRIM(s.program_name)) + ', database: ' + QUOTENAME(DB_NAME(s.dbid))
+ CASE WHEN EXISTS ( SELECT 1
FROM sys.dm_tran_active_transactions AS tat
JOIN sys.dm_tran_session_transactions AS tst
ON tst.transaction_id = tat.transaction_id
WHERE tat.name = 'implicit_transaction'
AND s.spid = tst.session_id
) THEN N' (IMPLICIT TRANSACTION)'
ELSE N''
END
+ ISNULL(', last command executed:<br/>
' + LTRIM(RTRIM((SELECT TOP 1 [text] FROM sys.dm_exec_sql_text(c.most_recent_sql_handle))))
, '')
, OpenMinutes = DATEDIFF(minute, s.last_batch, GETDATE())
FROM sys.sysprocesses s
INNER JOIN sys.dm_exec_connections c ON s.spid = c.session_id
INNER JOIN #SessionsWithLocks AS db ON s.spid = db.request_session_id
WHERE s.dbid <> 32767
AND s.status = 'sleeping'
AND s.open_tran > 0
--AND s.last_batch <= s.last_request_end_time
AND s.last_batch < DATEADD(MINUTE, -5, SYSDATETIME())
AND EXISTS (SELECT * FROM sys.dm_tran_locks
WHERE request_session_id = s.spid
AND NOT (resource_type = N'DATABASE' AND request_mode = N'S' AND request_status = N'GRANT' AND request_owner_type = N'SHARED_TRANSACTION_WORKSPACE'))
ORDER BY s.last_batch ASC
OPTION(MAXDOP 1);