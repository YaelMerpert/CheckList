SELECT s.name AS 'SchemaName', object_name(frag.object_id) AS 'TableName', si.name AS 'IndexName', frag.alloc_unit_type_desc AS 'AllocUnitType', frag.index_type_desc AS 'IndexType', frag.page_count AS 'PageCount', frag.index_depth AS 'IndexDepth', frag.avg_fragmentation_in_percent AS 'AvgFragmentationPercent', frag.fragment_count AS 'FragmentCount',
frag.avg_fragment_size_in_pages AS 'AvgFragmentPageCount', frag.object_id, frag.index_id, frag.partition_number
FROM sys.dm_db_index_physical_stats(DB_ID(),null,null,null,'LIMITED') frag 
LEFT OUTER JOIN sys.indexes si (NOLOCK) ON si.object_id = frag.object_id AND si.index_id = frag.index_id 
JOIN sys.objects o (NOLOCK) ON frag.object_id = o.object_id
JOIN sys.schemas AS s (NOLOCK) ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
--AND o.object_id not in (SELECT major_id FROM sys.extended_properties (NOLOCK) WHERE name = N'microsoft_database_tools_support')
AND frag.index_id <> 0
AND page_count > 50
AND avg_fragmentation_in_percent > 10
ORDER BY frag.page_count DESC


-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
SELECT I.NAME C_IXNAME,S.NAME SCHNAME,T.NAME TNAME,IP.AVG_FRAGMENTATION_IN_PERCENT [AVG FRAG PERCENT],IP.PAGE_COUNT,I.TYPE_DESC ,
       AVG_PAGE_SPACE_USED_IN_PERCENT AVGSPACEUSED, i.fill_factor FF
  FROM SYS.TABLES T
    JOIN SYS.SCHEMAS S
      ON T.SCHEMA_ID=S.SCHEMA_ID
        JOIN SYS.DM_DB_INDEX_PHYSICAL_STATS(DB_ID(), NULL, -null, NULL, null) IP
          ON  T.OBJECT_ID = IP.OBJECT_ID
        	JOIN SYS.INDEXES I 
	          ON I.OBJECT_ID = IP.OBJECT_ID           
                AND I.INDEX_ID = IP.INDEX_ID
                  WHERE IP.AVG_FRAGMENTATION_IN_PERCENT > 25 AND IP.PAGE_COUNT>50 AND I.TYPE_DESC = 'CLUSTERED'
				    ORDER BY PAGE_COUNT DESC

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
SELECT I.NAME N_IXNAME,S.NAME SCHNAME,T.NAME TNAME,IP.AVG_FRAGMENTATION_IN_PERCENT [AVG FRAG PERCENT],IP.PAGE_COUNT,I.TYPE_DESC,
       AVG_PAGE_SPACE_USED_IN_PERCENT AVGSPACEUSED, i.fill_factor FF
  FROM SYS.TABLES T
	JOIN SYS.SCHEMAS S
      ON T.SCHEMA_ID=S.SCHEMA_ID
		JOIN SYS.DM_DB_INDEX_PHYSICAL_STATS(DB_ID(), NULL, NULL, NULL, null) IP
          ON  T.OBJECT_ID = IP.OBJECT_ID
		    JOIN SYS.INDEXES I 
	          ON I.OBJECT_ID = IP.OBJECT_ID
                AND I.INDEX_ID = IP.INDEX_ID
                  WHERE IP.AVG_FRAGMENTATION_IN_PERCENT > 10 AND IP.PAGE_COUNT>50 AND I.NAME IS NOT NULL AND I.TYPE_DESC != 'CLUSTERED' -- AND T.name = 'DailyImpressionsFlightFreq'
				    ORDER BY PAGE_COUNT DESC,[AVG FRAG PERCENT] DESC
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------			 
--SELECT i.name IXname,S.name SCHname,T.name Tname,ip.avg_fragmentation_in_percent [Avg Frag Percent],ip.page_count,avg_page_space_used_in_percent AvgSpaceUsed
--  FROM sys.tables T
--    JOIN sys.schemas S
--      ON T.schema_id=S.schema_id
--	    JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ip
--          ON  T.OBJECT_ID = ip.OBJECT_ID
--	    	JOIN sys.indexes i 
--	          ON i.OBJECT_ID = ip.OBJECT_ID
--                AND i.index_id = ip.index_id
--                   WHERE ip.avg_fragmentation_in_percent > 20 AND page_count>101 AND i.type_desc = 'HEAP' and i.name is null
--				     order by page_count desc
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------	
sp_msforeachdb'
use [?]
SELECT db_name() DB,i.name IXname,S.name SCHname,T.name TAname,ip.avg_fragmentation_in_percent [Avg Frag Percent],ip.page_count,i.type_desc,avg_page_space_used_in_percent AvgSpaceUsed 
  FROM sys.tables T
    JOIN sys.schemas S
      ON T.schema_id=S.schema_id
        JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''DETAILED'') ip
          ON  T.OBJECT_ID = ip.OBJECT_ID
        	JOIN sys.indexes i 
	          ON i.OBJECT_ID = ip.OBJECT_ID
                AND i.index_id = ip.index_id
                  WHERE DB_ID()>4 and ip.avg_fragmentation_in_percent > 20 AND ip.page_count>101 and i.type_desc = ''CLUSTERED''
				    order by page_count desc'
GO
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
sp_msforeachdb'
use [?]
SELECT db_name() DB,i.name IXname,S.name SCHname,T.name TAname,ip.avg_fragmentation_in_percent [Avg Frag Percent],ip.page_count,i.type_desc,avg_page_space_used_in_percent AvgSpaceUsed
  FROM sys.tables T
	JOIN sys.schemas S
      ON T.schema_id=S.schema_id
		JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''DETAILED'') ip
          ON  T.OBJECT_ID = ip.OBJECT_ID
		    JOIN sys.indexes i 
	          ON i.OBJECT_ID = ip.OBJECT_ID
                AND i.index_id = ip.index_id
                  WHERE DB_ID()>4 and ip.avg_fragmentation_in_percent > 20 AND ip.page_count>101 and i.name is not null and i.type_desc != ''CLUSTERED''
				    order by page_count desc'
GO