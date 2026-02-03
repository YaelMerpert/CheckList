-- -- Get the last SQL Server restart time
declare @LastRestart DATETIME = (select sqlserver_start_time from sys.dm_os_sys_info);

-- Select unused/unmodified tables with space usage and row count
select 
    s.name as SchemaName,
    t.name as TableName,
    t.create_date,
    t.modify_date,
    --ISNULL(ius.last_user_seek, ius.last_user_scan) AS LastReadAccess,
    --ius.last_user_update AS LastWriteAccess,
    cast(sum(ps.used_page_count) * 8.0 / 1024 as DECIMAL(18,2)) as SpaceUsedMB,
    sum(case when ps.index_id in (0, 1) then ps.row_count else 0 end) as Row_Count,

    case 
        WHEN 
            ISNULL(ius.last_user_seek, ius.last_user_scan) < @LastRestart
            AND ISNULL(ius.last_user_update, '1900-01-01') < @LastRestart
            AND t.modify_date < @LastRestart
        THEN 'Has not changed or used since the last server startup'

        WHEN 
            (ISNULL(ius.last_user_seek, ius.last_user_scan) IS NULL OR ISNULL(ius.last_user_seek, ius.last_user_scan) < DATEADD(MONTH, -18, GETDATE()))
            AND (ius.last_user_update IS NULL OR ius.last_user_update < DATEADD(MONTH, -18, GETDATE()))
            AND t.modify_date < DATEADD(MONTH, -18, GETDATE())
        THEN 'Has not changed or used more than 18 months'
        ELSE 'Recently changed or used'
    END AS Status,

    CASE 
        WHEN NOT EXISTS (
            SELECT 1 
            FROM sys.indexes i 
            WHERE i.object_id = t.object_id AND i.type = 1 -- clustered index
        ) THEN 'No clustered index - read statistics may be incomplete'
        ELSE ''
    END AS IndexNote

FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.dm_db_index_usage_stats ius 
       ON t.object_id = ius.object_id AND ius.database_id = DB_ID()
LEFT JOIN sys.dm_db_partition_stats ps 
       ON t.object_id = ps.object_id
WHERE 
    (
        (ISNULL(ius.last_user_seek, ius.last_user_scan) IS NULL OR ISNULL(ius.last_user_seek, ius.last_user_scan) < DATEADD(MONTH, -18, GETDATE()))
        AND (ius.last_user_update IS NULL OR ius.last_user_update < DATEADD(MONTH, -18, GETDATE()))
        AND t.modify_date < DATEADD(MONTH, -18, GETDATE()))
    OR (
        ISNULL(ius.last_user_seek, ius.last_user_scan) < @LastRestart
        AND ISNULL(ius.last_user_update, '1900-01-01') < @LastRestart
        AND t.modify_date < @LastRestart
    )
    -- ? ????????? ??????? ? ?????????????
    AND 
	not EXISTS (
        SELECT 1
        FROM sys.sql_expression_dependencies d
        WHERE d.referenced_id = t.object_id
    )
GROUP BY 
    s.name, t.name, t.create_date, t.modify_date, 
    ISNULL(ius.last_user_seek, ius.last_user_scan), 
    ius.last_user_update, t.object_id
ORDER BY t.name;
