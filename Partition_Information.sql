---------------------------------------------
     -----  Partioned Tables  -----
---------------------------------------------
SELECT SCHEMA_NAME(c.schema_id) [Schema Name], OBJECT_NAME(a.object_id) [Table Name], a.name [Index Name], a.type_desc [Index Type],b.type
FROM (sys.indexes a INNER JOIN sys.tables c ON a.object_id = c.object_id) 
INNER JOIN sys.data_spaces b 
ON a.data_space_id = b.data_space_id
--WHERE b.type='PS' 
--and 
WHERE OBJECT_NAME(a.object_id)
 = 'RiskMng_RiskFactorResultDetails_live'
ORDER BY 2
---------------------------------------------
     -----  Show Partitioned Objects  -----
---------------------------------------------
SELECT DISTINCT
   p.[object_id],
   TbName = OBJECT_NAME(p.[object_id]), 
   index_name = i.[name],
   index_type_desc = i.type_desc,
   partition_scheme = ps.[name],
   data_space_id = ps.data_space_id,
   function_name = pf.[name],
   function_id = ps.function_id
FROM sys.partitions p
INNER JOIN sys.indexes i 
   on p.[object_id] = i.[object_id] 
   and p.index_id = i.index_id
inner join sys.data_spaces ds 
   on i.data_space_id = ds.data_space_id
inner join sys.partition_schemes ps 
 on ds.data_space_id = ps.data_space_id
inner JOIN sys.partition_functions pf 
   on ps.function_id = pf.function_id
WHERE OBJECT_NAME(p.[object_id]) = 'RiskMng_RiskFactorResultDetails_live'
 --OBJECT_NAME(p.[object_id]) like '%RiskMng_RiskFactorResult%'
order by    TbName, index_name ;
GO
--------------------------------------------------
----- show partitioned objects range values  -----
--------------------------------------------------
SELECT p.[object_id],
   OBJECT_NAME(p.[object_id]) AS TbName, 
   p.index_id,
   p.partition_number,
   p.rows,
   index_name = i.[name],
   index_type_desc = i.type_desc,
   i.data_space_id,
   ds1.NAME AS [FILEGROUP_NAME],
   pf.function_id,
   pf.[name] AS Pf_Name,
   pf.type_desc,
   pf.boundary_value_on_right,
   destination_data_space_id = dds.destination_id,
   prv.parameter_id,
   prv.value
from sys.partitions p
inner join sys.indexes i 
 on p.[object_id] = i.[object_id] 
 and p.index_id = i.index_id
inner JOIN sys.data_spaces ds 
 on i.data_space_id = ds.data_space_id
inner JOIN sys.partition_schemes ps 
 on ds.data_space_id = ps.data_space_id
inner JOIN sys.partition_functions pf 
 on ps.function_id = pf.function_id
inner join sys.destination_data_spaces dds 
 on dds.partition_scheme_id = ds.data_space_id 
 and p.partition_number = dds.destination_id
INNER JOIN sys.data_spaces ds1
 on ds1.data_space_id = dds.data_space_id 
left outer JOIN sys.partition_range_values prv 
 on prv.function_id = ps.function_id 
 and p.partition_number = prv.boundary_id
--WHERE p.[object_id] = object_id('orders')
 WHERE  OBJECT_NAME(p.[object_id]) = 'RiskMng_RiskFactorResultDetails_live'
order by TbName, p.index_id, p.partition_number ;
GO

--- 
-- alter Partition Function test_monthlyDateRange_pf() split RANGE ('2008-04-01');
-- Go
 
-- /* Associate the partition function with a partition scheme. */
--alter Partition Scheme [test_monthlyDateRange_ps] next USED [Filegroup_2004]; ---- all to (primary)
--Go

--- Max Partition Number on object (table or index)
SELECT MAX([partition_number]) AS [max_partition_number]
 FROM [sys].[dm_db_partition_stats] WITH (NOLOCK)
 WHERE
 OBJECT_NAME([object_id]) like '%RiskMng_RiskFactorResult%'
  --WHERE [object_id] = OBJECT_ID('person.Person_p')
   AND index_id = 3


   --select * from person.person_p where ModifiedDate > '20050101'

