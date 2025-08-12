set tran isolation level read uncommitted;


with main
as (select  t.name table_name
          , i.name index_name
          , fi.change_tracking_state_desc
          , fi.has_crawl_completed
          , fi.crawl_type_desc
          , fi.crawl_end_date
          , ius.last_user_update
          , ius.last_user_seek
          , (
               select    name + ','
               from  sys.fulltext_index_columns fc
                     inner join sys.columns     c on c.object_id = fc.object_id
                                                     and  c.column_id = fc.column_id
               where fc.object_id = fi.object_id
               for xml path('')
            )      columns
          , (case
                when fi.crawl_end_date < isnull(ius.last_user_update, ius.last_user_seek) then 'ALTER FULLTEXT INDEX ON ' + schema_name(t.schema_id) + '.' +t.name + ' SET CHANGE_TRACKING MANUAL; ALTER FULLTEXT INDEX ON ' +schema_name(t.schema_id) + '.' + t.name + ' SET CHANGE_TRACKING AUTO'
             else ''
             end
            )      Command
    from sys.fulltext_indexes                  fi
         inner join sys.indexes                i on i.index_id = fi.unique_index_id
                                                    and  i.object_id = fi.object_id
         inner join sys.tables                 t on t.object_id = fi.object_id
         left join sys.dm_db_index_usage_stats ius on ius.index_id = fi.unique_index_id
                                                      and ius.object_id = fi.object_id
                                                      and ius.database_id = db_id())
select   *
from  main
where main.Command <> '';



----SELECT getdate() as "RunTime", st.text, qp.query_plan, a.* FROM sys.dm_exec_requests a CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) as st CROSS APPLY sys.dm_exec_query_plan(a.plan_handle) as qp-- where session_id in(221)

SELECT OBJECT_SCHEMA_NAME(table_id) + '.' + OBJECT_NAME(table_id) AS tableName, COUNT(*) AS num_fragments, SUM(row_count) AS row_count, CONVERT(DECIMAL(9,2), SUM(data_size/(1024.*1024.))) AS fulltext_size_mb
FROM sys.fulltext_index_fragments
GROUP BY table_id
ORDER BY fulltext_size_mb desc

-- Compute fragmentation information for all full-text indexes on the database


	IF OBJECT_ID('tempdb..#fulltextFragmentationDetails') IS NOT NULL DROP TABLE #fulltextFragmentationDetails


SELECT c.fulltext_catalog_id, c.name AS fulltext_catalog_name, i.change_tracking_state,
    i.object_id, OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS object_name,
    f.num_fragments, f.fulltext_mb, f.largest_fragment_mb,
    100.0 * (f.fulltext_mb - f.largest_fragment_mb) / NULLIF(f.fulltext_mb, 0) AS fulltext_fragmentation_in_percent
INTO #fulltextFragmentationDetails
FROM sys.fulltext_catalogs c
JOIN sys.fulltext_indexes i
    ON i.fulltext_catalog_id = c.fulltext_catalog_id
JOIN (
    -- Compute fragment data for each table with a full-text index
    SELECT table_id,
        COUNT(*) AS num_fragments,
        CONVERT(DECIMAL(9,2), SUM(data_size/(1024.*1024.))) AS fulltext_mb,
        CONVERT(DECIMAL(9,2), MAX(data_size/(1024.*1024.))) AS largest_fragment_mb
    FROM sys.fulltext_index_fragments
    GROUP BY table_id
) f
    ON f.table_id = i.object_id

-- Apply a basic heuristic to determine any full-text indexes that are "too fragmented"
-- We have chosen the 10% threshold based on performance benchmarking on our own data
-- Our over-night maintenance will then drop and re-create any such indexes
SELECT *
FROM #fulltextFragmentationDetails
WHERE fulltext_fragmentation_in_percent >= 10
    AND fulltext_mb >= 1 -- No need to bother with indexes of trivial size


	IF OBJECT_ID('tempdb..#fulltextFragmentationDetails') IS NOT NULL DROP TABLE #fulltextFragmentationDetails