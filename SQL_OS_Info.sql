DECLARE @Version int, @Command NVARCHAR(1000)
SET @Version=convert (int,REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')),2), '.', ''))
IF @Version = 9
  BEGIN
	SET @Command='SELECT cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,(physical_memory_in_bytes) /1024 as physical_memory_kb,(virtual_memory_in_bytes/1024) as ''virtual_memory_kb'',
	CONVERT(bigint,(bpool_committed/1024)) as ''committed_kb'',CONVERT(bigint,(bpool_commit_target/1024)) as ''committed_target_kb'',convert(bigint,(bpool_visible/1024)) as ''visible_target_kb'',
	stack_size_in_bytes,os_quantum,os_error_mode,os_priority_class,max_workers_count,scheduler_count,scheduler_total_count,deadlock_monitor_serial_number
	FROM sys.dm_os_sys_info'
	EXEC sp_executesql @Command
  END
ELSE IF @Version = 10
  BEGIN
  SET @Command='SELECT cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,(physical_memory_in_bytes) /1024 as physical_memory_kb,(virtual_memory_in_bytes/1024) as ''virtual_memory_kb'',
	convert(bigint,(bpool_committed/1024)) as ''committed_kb'',convert(bigint,(bpool_commit_target/1024)) as ''committed_target_kb'',convert(bigint,(bpool_visible/1024)) as ''visible_target_kb'',
	stack_size_in_bytes,os_quantum,os_error_mode,os_priority_class,max_workers_count,scheduler_count,scheduler_total_count,deadlock_monitor_serial_number,sqlserver_start_time_ms_ticks,
	sqlserver_start_time,
	null as ''virtual_machine_type'',null as ''virtual_machine_type_desc''
	FROM sys.dm_os_sys_info'
  EXEC sp_executesql @Command
  END
ELSE IF @Version >= 11
  BEGIN
  SET @Command='SELECT cpu_ticks,ms_ticks,cpu_count,hyperthread_ratio,physical_memory_kb,virtual_memory_kb,committed_kb,committed_target_kb,visible_target_kb,stack_size_in_bytes,os_quantum,os_error_mode,
	os_priority_class,max_workers_count,scheduler_count,scheduler_total_count,deadlock_monitor_serial_number,sqlserver_start_time_ms_ticks,sqlserver_start_time,affinity_type,affinity_type_desc,
	process_kernel_time_ms,process_user_time_ms,time_source,time_source_desc,virtual_machine_type,virtual_machine_type_desc
	FROM sys.dm_os_sys_info'
  EXEC sp_executesql @Command
  END

