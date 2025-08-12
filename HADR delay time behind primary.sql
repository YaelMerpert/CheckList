



SELECT CAST(DB_NAME(drs.database_id)as VARCHAR(40)) database_name,
Convert(VARCHAR(20),drs.last_commit_time,22) last_commit_time
,CAST(CAST(((DATEDIFF(s,drs.last_commit_time,GetDate()))/3600) as varchar) + ' hour(s), '
+ CAST((DATEDIFF(s,drs.last_commit_time,GetDate())%3600)/60 as varchar) + ' min, '
+ CAST((DATEDIFF(s,drs.last_commit_time,GetDate())%60) as varchar) + ' sec' as VARCHAR(30)) time_behind_primary
,drs.redo_queue_size
,drs.redo_rate
,CONVERT(VARCHAR(20),DATEADD(mi,(drs.redo_queue_size/drs.redo_rate/60.0),GETDATE()),22) estimated_completion_time
,CAST((drs.redo_queue_size/drs.redo_rate/60.0) as decimal(10,2)) [estimated_recovery_time_minutes]
,(drs.redo_queue_size/drs.redo_rate) [estimated_recovery_time_seconds]
,CONVERT(VARCHAR(20),GETDATE(),22) [current_time],
drs.truncation_lsn,drs.last_received_lsn
FROM sys.dm_hadr_database_replica_states drs
WHERE drs.last_redone_time is not null
--and CAST(DB_NAME(database_id)as VARCHAR(40)) ='DATABASE_NAME'
