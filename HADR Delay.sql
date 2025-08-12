select name, log_reuse_wait,log_reuse_wait_desc from sys.databases;

select * from sys.dm_hadr_database_replica_states;




SELECT arcs.replica_server_name, d.name, d.log_reuse_wait_desc, drs.log_send_queue_size,drs.redo_queue_size
FROM master.sys.databases d
INNER JOIN master.sys.dm_hadr_database_replica_states drs
ON d.database_id=drs.database_id
INNER JOIN master.sys.dm_hadr_availability_replica_cluster_states arcs
ON drs.replica_id=arcs.replica_id
ORDER BY name ASC