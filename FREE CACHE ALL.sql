
  Customs_DBA.dbo.sp_who_request

/*
DBCC FREEPROCCACHE
----------------------
Removes all elements from the plan cache, 
removes a specific plan from the plan cache by specifying a plan handle or SQL handle, 
or removes all cache entries associated with a specified resource pool.
*/
DBCC FREEPROCCACHE; 
/*
DBCC DROPCLEANBUFFERS
----------------------
Removes all clean buffers from the buffer pool.
*/
DBCC DROPCLEANBUFFERS;


DBCC FREESYSTEMCACHE('All')
DBCC FREESYSTEMCACHE ('Temporary Tables & Table Variables')
DBCC FREESYSTEMCACHE ('Customs_PilotReplica')
DBCC FREESYSTEMCACHE ('tempdb')



DBCC FREESESSIONCACHE
DBCC FREEPROCCACHE


