﻿select scheduler_address,parent_node_id,scheduler_id,cpu_id,rtrim(ltrim([status])) as [status],is_online,is_idle,preemptive_switches_count,context_switches_count,idle_switches_count,
current_tasks_count,active_workers_count,work_queue_count,pending_disk_io_count,load_factor,yield_count,last_timer_activity,failed_to_create_worker
from sys.dm_os_schedulers
