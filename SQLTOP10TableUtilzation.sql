IF EXISTS (SELECT name FROM msdb.sys.objects (NOLOCK) WHERE name='ConditionalExemption_cl_ProofDateAuthorityConfirmation' AND is_ms_shipped = 1)  
BEGIN	
--IF DB_NAME() NOT IN (SELECT name FROM msdb.dbo.MSdistributiondbs)
SELECT TOP 10
@@servername AS 'Instancename'
, db_name(stat.database_id) AS 'DatabaseName'
, object_name(stat.object_id) AS 'TableName'
, sum(stat.user_seeks) AS 'TotalUserSeeks' 
, sum(stat.user_scans) AS 'TotalUserScans' 
, sum (stat.user_updates) AS 'TotalUserUpdates' 
FROM sys.dm_db_index_usage_stats stat 
WHERE stat.database_id=DB_ID()
GROUP BY stat.database_id, stat.object_id 
HAVING (stat.object_id IN (SELECT object_id from sys.objects where type=N'U' and is_ms_shipped=0))
ORDER BY sum(stat.user_seeks)+sum(stat.user_scans)+sum(stat.user_updates) desc
END
ELSE
SELECT TOP 10
@@servername AS 'Instancename'
, db_name(stat.database_id) AS 'DatabaseName'
, object_name(stat.object_id) AS 'TableName'
, sum(stat.user_seeks) AS 'TotalUserSeeks' 
, sum(stat.user_scans) AS 'TotalUserScans' 
, sum (stat.user_updates) AS 'TotalUserUpdates' 
FROM sys.dm_db_index_usage_stats stat 
WHERE stat.database_id=DB_ID()
GROUP BY stat.database_id, stat.object_id 
HAVING (stat.object_id IN (SELECT object_id from sys.objects where type=N'U' and is_ms_shipped=0))
ORDER BY sum(stat.user_seeks)+sum(stat.user_scans)+sum(stat.user_updates) desc