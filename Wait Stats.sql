

--Detecting top wait types in the system
;with Waits
as
(
select
wait_type, wait_time_ms, waiting_tasks_count,
100. * wait_time_ms / SUM(wait_time_ms) over() as Pct,
row_number() over(order by wait_time_ms desc) AS RowNum
from sys.dm_os_wait_stats with (nolock)
where
wait_type not in /* Filtering out non-essential system waits */
(N'CLR_SEMAPHORE',N'LAZYWRITER_SLEEP',N'RESOURCE_QUEUE'
,N'SLEEP_TASK',N'SLEEP_SYSTEMTASK',N'SQLTRACE_BUFFER_FLUSH'
,N'WAITFOR',N'LOGMGR_QUEUE',N'CHECKPOINT_QUEUE'
,N'REQUEST_FOR_DEADLOCK_SEARCH',N'XE_TIMER_EVENT'
,N'BROKER_TO_FLUSH',N'BROKER_TASK_STOP',N'CLR_MANUAL_EVENT'
,N'CLR_AUTO_EVENT',N'DISPATCHER_QUEUE_SEMAPHORE'
,N'FT_IFTS_SCHEDULER_IDLE_WAIT',N'XE_DISPATCHER_WAIT'
,N'XE_DISPATCHER_JOIN',N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
,N'ONDEMAND_TASK_QUEUE',N'BROKER_EVENTHANDLER',N'SLEEP_BPOOL_FLUSH'
,N'SLEEP_DBSTARTUP',N'DIRTY_PAGE_POLL',N'BROKER_RECEIVE_WAITFOR'
,N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'WAIT_XTP_CKPT_CLOSE'
,N'SP_SERVER_DIAGNOSTICS_SLEEP',N'BROKER_TRANSMITTER'
,N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP','MSQL_XP'
,N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
,N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG')
)
select
w1.wait_type as [Wait Type]
,w1.waiting_tasks_count as [Wait Count]
,convert(decimal(12,3), w1.wait_time_ms / 1000.0) as [Wait Time]
,CONVERT(decimal(12,1), w1.wait_time_ms /
w1.waiting_tasks_count) as [Avg Wait Time]
,convert(decimal(6,3), w1.Pct) as [Percent]
,convert(decimal(6,3), sum(w2.Pct)) as [Running Percent]
from
Waits w1 join Waits w2 on
w2.RowNum <= w1.RowNum
group by
w1.RowNum, w1.wait_type, w1.wait_time_ms, w1.waiting_tasks_count, w1.Pct
having
sum(w2.Pct) - w1.pct < 95
option (recompile);





SELECT *
FROM sys.dm_os_wait_stats
WHERE wait_type = 'WAIT_XTP_HOST_WAIT';

CHECKPOINT

SELECT *
FROM sys.dm_os_wait_stats
WHERE wait_type = 'WAIT_XTP_HOST_WAIT';


SELECT *
FROM sys.dm_os_wait_stats
WHERE wait_type = 'WAIT_XTP_CKPT_CLOSE';




SELECT *
FROM sys.dm_os_spinlock_stats
ORDER BY spins DESC;