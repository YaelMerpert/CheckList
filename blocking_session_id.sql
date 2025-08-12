
 DROP TABLE IF EXISTS #A
  DROP TABLE IF EXISTS #B
   DROP TABLE IF EXISTS #final
  

 DECLARE @From DATETIME = '2018-04-16 12:12:00.000'
  DECLARE @To DATETIME = '2018-04-16 12:15:00.000'
  


SELECT DISTINCT session_id
			  , WIALM.blocking_session_id
			  , WIALM.objectid
INTO #A
FROM CustomsLog_Pilot._Admin_.WhoIsActive_LightMonitor WIALM
WHERE WIALM.InsertDate BETWEEN @From AND @To
AND WIALM.blocking_session_id > 0


WITH cte1
  AS
   (SELECT session_id
		 , blocking_session_id
		 , 1 [level]
		 , CAST(blocking_session_id AS VARCHAR(MAX)) lockpath
	FROM #A
	--WHERE blocking_session_id  0
	--UNION ALL
	--SELECT a.session_id
	--	 , cte1.blocking_session_id
	--	 , [level] + 1 [level]
	--	 , lockpath + '--->' + CAST(cte1.session_id AS VARCHAR(MAX)) a
	--FROM #A a
	--	 INNER JOIN cte1 ON cte1.session_id = a.blocking_session_id
	)

SELECT * FROM cte1

SELECT DISTINCT *
INTO #B
FROM cte1
UNION
SELECT blocking_session_id
	 , NULL
	 , 0
	 , CAST(blocking_session_id AS VARCHAR(500))
FROM cte1
WHERE [level] > 0


SELECT blocking_session_id
     ,session_id
	 , level
	 , lockpath 
FROM #B
ORDER BY blocking_session_id 

GO


 WITH cte AS (
                SELECT session_id         ,blocking_session_id,    [level] FROM  #B
               )

, cte1 AS(

            SELECT session_id,blocking_session_id, MAX([level]) max_level
            FROM #B a
            GROUP BY session_id,blocking_session_id
            )
   ,cte2 AS ( 
SELECT DISTINCT  a.blocking_session_id primary_blocking_session_id,[level] locklevel, b.session_id Secundry_blocking_session_id
FROM cte  a INNER JOIN cte1 b
ON a.blocking_session_id=b.blocking_session_id AND a.level=b.max_level+1
)




SELECT a.session_id,
CASE WHEN blocking_session_id IS NULL AND [level]=0 THEN  session_id ELSE blocking_session_id END  primary_blocking_session_id,
Secundry_blocking_session_id  current_blocking_session_id,
[level],
CASE WHEN blocking_session_id IS NULL THEN lockpath ELSE lockpath+'-->'+CAST (session_id AS VARCHAR (560))END lockpath
INTO #final
FROM #B a left JOIN cte2 b ON b.primary_blocking_session_id=a.blocking_session_id AND a.[level]=b.locklevel-1

;
WITH objectname AS (
SELECT session_id,OBJECT_NAME(objectid) OBname  FROM #a 
)

,cteobname AS (
				SELECT session_id
					 , STUFF ((
								  SELECT '******' + OBname
								  FROM objectname
								  WHERE (session_id = Results.session_id)
								  FOR XML PATH ( '' ), TYPE
							  ).value ( '(./text())[1]', 'VARCHAR(MAX)' )
							, 1
							, 2
							, ''
							 ) AS ObjectValues
				FROM objectname Results
				GROUP BY session_id
                  )


SELECT * FROM cteobname