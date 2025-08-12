 
DECLARE @AlertTimeStart DATETIME = '20141223' 
DECLARE @AlertTimeEnd DATETIME = '20141224'   

EXECUTE [Maintenance].[_Admin_].[usp_Maintenance_GetTimeOutInfo] @AlertTimeStart, @AlertTimeEnd 

--מציאת DeadLock 
DECLARE @AlertTimeStart2 DATETIME = '20141223' 
DECLARE @AlertTimeEnd2 DATETIME = '20141224' 

EXECUTE [Maintenance].[_Admin_].[usp_Maintenance_GetDeadLockInfo] @AlertTimeStart2, @AlertTimeEnd2 

--מציאת נעילות 
DECLARE @AlertTimeStart3 DATETIME = '20141223' 
DECLARE @AlertTimeEnd3 DATETIME = '20141224' 

EXECUTE [Maintenance].[_Admin_].[usp_Locks_GetBlockingInfo] @AlertTimeStart3, @AlertTimeEnd3


