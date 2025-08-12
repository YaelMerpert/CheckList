

--SELECT d.database_id, d.name , last_hardened_lsn
--FROM sys.dm_hadr_database_replica_states rs
--INNER JOIN sys.databases d ON d.database_id = rs.database_id


SELECT AG.name AS [AvailabilityGroupName],
	   ISNULL ( agstates.primary_replica, '' ) AS [PrimaryReplicaServerName],
	   ISNULL ( arstates.role, 3 ) AS [LocalReplicaRole],
	   dbcs.database_name AS [DatabaseName],
	   ISNULL ( dbrs.synchronization_state, 0 ) AS [SynchronizationState],
	   ISNULL ( dbrs.synchronization_state_desc, 0 ) AS [SynchronizationStateDescription],
	   ISNULL ( dbrs.is_suspended, 0 ) AS [IsSuspended],
	   ISNULL ( dbcs.is_database_joined, 0 ) AS [IsJoined]
	   ,AR.primary_role_allow_connections
	   ,AR.primary_role_allow_connections_desc
FROM master.sys.availability_groups AS AG
	 LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states AS agstates ON AG.group_id = agstates.group_id
	 INNER JOIN master.sys.availability_replicas AS AR ON AG.group_id = AR.group_id
	 INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates ON AR.replica_id = arstates.replica_id
																			  AND arstates.is_local = 1
	 INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs ON arstates.replica_id = dbcs.replica_id
	 LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs ON dbcs.replica_id = dbrs.replica_id
																		   AND dbcs.group_database_id = dbrs.group_database_id
WHERE synchronization_state != 2
ORDER BY AG.name ASC, dbcs.database_name;






SELECT dbs.database_id
	 , dbs.name
	 , dbs.log_reuse_wait_desc
	 , ars.is_local
	 , ars.role
	 , ars.role_desc
	 , ars.operational_state
	 , ars.operational_state_desc
	 , ars.connected_state_desc
	 , ars.recovery_health
	 , ars.recovery_health_desc
	 , ars.synchronization_health_desc
	 , ars.last_connect_error_description
	 , ars.last_connect_error_timestamp
FROM sys.dm_hadr_availability_replica_states ars
	 INNER JOIN sys.databases dbs ON ars.replica_id = dbs.replica_id
	 WHERE  ars.recovery_health =0
