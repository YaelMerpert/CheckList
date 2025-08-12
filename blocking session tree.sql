



  


  DECLARE @From DATETIME = '20180503 11:27:00.000'
  DECLARE @To DATETIME = '20180503 11:27:03.000'




DROP TABLE IF EXISTS #A

SELECT DISTINCT WIALM.blocking_session_id
			  ,WIALM.session_id
			  , WIALM.objectid
			  , WIALM.wait_type
			  , WIALM.wait_resource
			  , WIALM.start_time			  
INTO #A
FROM CustomsLog_Pilot._Admin_.WhoIsActive_LightMonitor WIALM
WHERE WIALM.InsertDate BETWEEN @From AND @To
		AND WIALM.blocking_session_id > 0

INSERT  INTO #A
SELECT DISTINCT WIALM.blocking_session_id
			  ,WIALM.session_id
			  , WIALM.objectid
			  , WIALM.wait_type
			  , WIALM.wait_resource
			  , WIALM.start_time
FROM #A A 
INNER JOIN CustomsLog_Pilot._Admin_.WhoIsActive_LightMonitor WIALM  ON WIALM.session_id = A.blocking_session_id
WHERE WIALM.InsertDate BETWEEN @From AND @To
	
------------------------------------------------------------------------------


;WITH Cte1 AS (
				SELECT  blocking_session_id
					 , session_id
					 , 0 AS level
					 , CONVERT(NVARCHAR(4000),session_id) [Path]
					 , objectid
					 , OBJECT_NAME( objectid ) objectname 
					 , wait_type
					 , wait_resource
					 , start_time
				FROM #A
				WHERE blocking_session_id = 0
				UNION ALL 
				SELECT 
					  A.blocking_session_id
					 , A.session_id
					 , C.level + 1 AS level
					 , [Path]  + ' --> '  +CONVERT(NVARCHAR(4000),A.session_id) AS [Path]
					 , A.objectid
					 , OBJECT_NAME( A.objectid ) objectname 
					 , A.wait_type
					 , A.wait_resource
					 , A.start_time
				FROM Cte1 C
				CROSS APPLY (SELECT A.*, ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY session_id ) RN
							FROM #A A 
							WHERE  A.blocking_session_id = C.session_id
							AND A.blocking_session_id > 0
							)A
				WHERE A.RN = 1
				)


SELECT * FROM Cte1





