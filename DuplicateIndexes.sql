;with XMLTable AS (
select object_name (x.object_id) as 'TableName' ,schema_name(o.schema_id) as SchemaName ,x.object_id,x.name,x.index_id,x.using_xml_index_id,x.secondary_type,CONVERT(nvarchar(max),x.secondary_type_desc) as secondary_type_desc, ic.column_id 
from 
	sys.xml_indexes x (NOLOCK)  
	join sys.objects o  (NOLOCK) on x.object_id = o.object_id
	join sys.index_columns  (NOLOCK) ic on x.object_id = ic.object_id and x.index_id = ic.index_id
),
DuplicatesXMLTable AS(
select 
	x1.SchemaName,x1.TableName,x1.name as IndexName,x2.name as DuplicateIndexName, x1.secondary_type_desc as IndexType, x1.index_id, x1.object_id
	,ROW_NUMBER() OVER(ORDER BY x1.SchemaName, x1.TableName,x1.name, x2.name) AS seq1, ROW_NUMBER() OVER(ORDER BY x1.SchemaName DESC, x1.TableName DESC,x1.name DESC, x2.name DESC) AS seq2
from XMLTable x1
	join XMLTable x2
	on x1.object_id = x2.object_id
	and x1.index_id < x2.index_id
	and x1.using_xml_index_id = x2.using_xml_index_id
	and x1.secondary_type = x2.secondary_type
	
),IndexColumns AS(
select distinct  schema_name (o.schema_id) as 'SchemaName',object_name(o.object_id) as TableName, i.Name as IndexName, o.object_id,i.index_id,i.type,
(select case key_ordinal when 0 then NULL else '['+col_name(k.object_id,column_id) +']' end as [data()]
from sys.index_columns  (NOLOCK) as k
where k.object_id = i.object_id
and k.index_id = i.index_id
order by key_ordinal, column_id
for xml path('')) as cols
from sys.indexes  (NOLOCK) as i
inner join sys.objects o  (NOLOCK) on i.object_id =o.object_id 
inner join sys.index_columns ic  (NOLOCK) on ic.object_id =i.object_id and ic.index_id =i.index_id
inner join sys.columns c  (NOLOCK) on c.object_id = ic.object_id and c.column_id = ic.column_id
where  o.type = 'U' and i.index_id <>0 and i.type <>3 and i.type <>6
group by o.schema_id,o.object_id,i.object_id,i.Name,i.index_id,i.type
),
DuplicatesTable AS
(
SELECT	ic1.SchemaName,ic1.TableName,ic1.IndexName,ic1.object_id, ic2.IndexName as DuplicateIndexName, ic1.cols as IndexCols, ic1.index_id,
ROW_NUMBER() OVER(ORDER BY ic1.SchemaName, ic1.TableName,ic1.IndexName, ic2.IndexName) AS seq1, ROW_NUMBER() OVER(ORDER BY ic1.SchemaName DESC, ic1.TableName DESC, ic1.IndexName DESC, ic2.IndexName DESC) AS seq2
from IndexColumns ic1
	join IndexColumns ic2
	on ic1.object_id = ic2.object_id
	and ic1.index_id < ic2.index_id
	and ic1.cols = ic2.cols
)
SELECT TOP 10 
	@@SERVERNAME AS InstanceName, dt.seq1 + dt.seq2 - 1 AS NbOccurences,
	SchemaName,TableName, IndexName,DuplicateIndexName, IndexCols, index_id, object_id, 0 AS IsXML
	FROM DuplicatesTable dt
UNION ALL
SELECT TOP 10
	@@SERVERNAME AS InstanceName, dtxml.seq1 + dtxml.seq2 - 1  AS NbOccurences,
	SchemaName,TableName,IndexName,DuplicateIndexName, IndexType COLLATE SQL_Latin1_General_CP1_CI_AS, index_id, object_id, 1 AS IsXML
FROM DuplicatesXMLTable dtxml