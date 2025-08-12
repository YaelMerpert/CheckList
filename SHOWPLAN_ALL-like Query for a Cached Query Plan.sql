-- SHOWPLAN_ALL-like Query for a Cached Query Plan. 
 
-- Get the handle of the plan of your interest. 
DECLARE @plan_handle VARBINARY(64); 
 
-- Please modify the first query to get the handle for the plan of your interest !!! 
-- Select e.g. from query stats ... 
--SET @plan_handle = ( SELECT TOP 1
--                            EQS.plan_handle
--                     FROM   sys.dm_exec_query_stats AS EQS
--                     ORDER BY EQS.total_worker_time DESC
--                   ); 
-- or define a know handle plan 
--SET @plan_handle = 0x0600070083E73809803CA87A0E00000001000000000000000000000000000000000000000000000000000000; 

-- First select the ShowPlan to compare; click on the link to open the graphical execution plan. 
DECLARE @ShortDatabaseName VARCHAR(50) = 'Customs_Dev';
DECLARE @DatabaseName VARCHAR(50) = '[' + @ShortDatabaseName + ']';
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF OBJECT_ID('tempdb..#SPWithMOT') IS NOT NULL
    DROP TABLE #SPWithMOT;
CREATE TABLE #SPWithMOT
    (
      ObjectName VARCHAR(256) NOT NULL ,
      ObjectID INT NOT NULL
    );
INSERT  #SPWithMOT
        SELECT  SCH.name + '.' + OBJ.name AS ObjectName ,
                OBJ.object_id AS ObjectID 
       --,Shared.ufn_Util_clr_Conc(REFSCH.name + '.' + REFOBJ.name) AS ReferencedObjectName
        FROM    sys.sql_expression_dependencies AS DEP
                INNER JOIN sys.objects AS OBJ ON DEP.referencing_id = OBJ.object_id
                INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id
                INNER JOIN sys.tables AS REFOBJ ON DEP.referenced_id = REFOBJ.object_id
                INNER JOIN sys.schemas AS REFSCH ON REFOBJ.schema_id = REFSCH.schema_id
        WHERE   OBJ.type = 'P'
                AND REFOBJ.type = 'U'
                AND REFOBJ.is_memory_optimized = 1
        GROUP BY SCH.name + '.' + OBJ.name ,
                OBJ.object_id 
-- Select the SQL statements included in the batch with statistic information. 

-- Now split the xml data into separate nodes. 
;
WITH 
 XMLNAMESPACES 
    (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan' 
            ,N'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS ShowPlan) 
,RelOp AS (
    SELECT 
                     Stmt.node.value(N'@StatementId[1]', N'int') AS StatementId 
           ,ISNULL(Stmt.node.value(N'@StatementSubTreeCost[1]', N'float'), 0.0) AS StatementSubTreeCost 
           ,RelOp.node.value(N'@NodeId[1]', N'int') AS NodeId 
           ,RelOp.node.value(N'../../@NodeId[1]', N'int') AS ParentNodeId 
           ,RelOp.node.value(N'@PhysicalOp[1]', N'varchar(255)') AS PhysicalOp 
           ,RelOp.node.value(N'@LogicalOp[1]', N'varchar(255)') AS LogicalOp 
           ,RelOp.node.value(N'@EstimateRows[1]', N'float') AS EstRows 
           ,RelOp.node.value(N'@AvgRowSize[1]', N'float') AS AvgRowSize 
           ,RelOp.node.value(N'@Parallel[1]', N'int') AS Parallel 
           ,RelOp.node.value(N'@EstimateRebinds[1]', N'float') AS EstRebinds 
           ,RelOp.node.value(N'@EstimateRewinds[1]', N'float') AS EstRewinds 
           ,N'Dir=' + RelOp.node.value(N'./IndexScan[1]/@ScanDirection[1]', N'varchar(20)') 
            + N',Ordered=' + CASE WHEN RelOp.node.value(N'./IndexScan[1]/@Ordered[1]', N'int') = 0 THEN N'False' ELSE N'True' END 
            + N',Forced=' + CASE WHEN RelOp.node.value(N'./IndexScan[1]/@ForcedIndex[1]', N'int') = 0 THEN N'False' ELSE N'True' END 
           AS IdxScan 
           ,N'In=' + RelOp.node.value(N'./MemoryFractions[1]/@Input[1]', N'varchar(20)') + N', ' 
            + N',Out=' + RelOp.node.value(N'./MemoryFractions[1]/@Output[1]', N'varchar(20)') + N', ' 
           AS MemFraction ,
                 ISNULL(TableScan.node.value(N'@Schema[1]', N'varchar(255)') , IndexScan.node.value(N'@Schema[1]', N'varchar(255)')) + N'.'
            + ISNULL(TableScan.node.value(N'@Table[1]', N'varchar(255)'), IndexScan.node.value(N'@Table[1]', N'varchar(255)'))  AS  TableList,
                     spmot.ObjectName
                     ,QS.plan_handle,
                     EQP.query_plan,
                     TableScan.node.value(N'@Storage[1]', N'varchar(255)')TableType1,
                     IndexScan.node.value(N'@Storage[1]', N'varchar(255)')TableType2
     FROM     (SELECT       DISTINCT QS.sql_handle,QS.plan_handle
                     FROM   sys.dm_exec_query_stats QS
                     WHERE  QS.execution_count > 1
                                  )QS
                     CROSS APPLY sys.dm_exec_sql_text(sql_handle) qt
                     INNER JOIN #SPWithMOT spmot ON qt.objectid = spmot.ObjectID
                     CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS EQP 
                     CROSS APPLY EQP.query_plan.nodes(N'/ShowPlanXML/BatchSequence/Batch/Statements/*') AS Stmt(node) 
                     CROSS APPLY Stmt.node.nodes(N'(.//RelOp)') AS RelOp(node)
                     --CROSS APPLY RelOp.node.nodes(N'(.//TableScan)') AS TT(node)
                     OUTER APPLY RelOp.node.nodes(N'(.//TableScan/Object)') AS TableScan(node)
                     OUTER APPLY RelOp.node.nodes(N'(.//IndexScan/Object)') AS IndexScan(node)
                     --CROSS APPLY RelOp.node.nodes(N'(.//OutputList/ColumnReference)') AS OutLs(node) 
       
       WHERE  qt.dbid IS NOT NULL
                     AND qt.objectid IN (SELECT ObjectID FROM #SPWithMOT)   
                     AND EQP.dbid = DB_ID(@ShortDatabaseName)--COALESCE(DB_NAME(CAST(pa.value AS INT)), '') = REPLACE(REPLACE(@DatabaseName,'[',''),']','')

                     AND ISNULL(TableScan.node.value(N'@Storage[1]', N'varchar(255)'),IndexScan.node.value(N'@Storage[1]', N'varchar(255)'))  = 'MemoryOptimized'
) 
SELECT 
        RelOp.ObjectName , RelOp.TableList
        
FROM   RelOp
WHERE  RelOp.LogicalOp = 'Clustered Index Scan'
UNION  ALL
SELECT RelOp.ObjectName , RelOp.TableList
FROM   RelOp
WHERE  RelOp.LogicalOp = 'Index Scan'
UNION  ALL
SELECT RelOp.ObjectName , RelOp.TableList
FROM   RelOp
WHERE  RelOp.LogicalOp = 'Table Scan'
ORDER BY  RelOp.ObjectName, RelOp.TableList

