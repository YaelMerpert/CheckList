USE [Customs_DEV]
GO
select i.[name] as index_name,
    substring(column_names, 1, len(column_names)-1) as [columns],
    case when i.[type] = 1 then 'Clustered index'
        when i.[type] = 2 then 'Nonclustered unique index'
        when i.[type] = 3 then 'XML index'
        when i.[type] = 4 then 'Spatial index'
        when i.[type] = 5 then 'Clustered columnstore index'
        when i.[type] = 6 then 'Nonclustered columnstore index'
        when i.[type] = 7 then 'Nonclustered hash index'
        end as index_type,
    case when i.is_unique = 1 then 'Unique'
        else 'Not unique' end as [unique],
    schema_name(t.schema_id) + '.' + t.[name] as table_view, 
    case when t.[type] = 'U' then 'Table'
        when t.[type] = 'V' then 'View'
        end as [object_type]
from sys.objects t
    inner join sys.indexes i
        on t.object_id = i.object_id
    cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = t.object_id
                        and ic.index_id = i.index_id
                            order by key_ordinal
                            for xml path ('') ) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
order by i.[name]

--*****************************************************************************************
--FRAGMENTATION LEVEL-- TEMPERATURE :-)

   declare @DB sysname = 'Customs_DEV';

    select s.name schema_name, t.name TableName, i.name IndexName, d.avg_fragmentation_in_percent Fragmentation
    from   sys.dm_db_index_physical_stats( DB_ID(@DB), null, null, null, null) d
           inner join sys.tables  t on d.object_id = t.object_id
           inner join sys.schemas s on t.schema_id = s.schema_id
           inner join sys.indexes i on d.object_id = i.object_id AND d.index_id = i.index_id
    where  d.index_id > 0 and d.page_count > 8
    order by fragmentation desc

	--**********************************************************************************
--INDEXES REBUILD--

begin
    declare @databaseName sysname = N'Customs_dev';
    declare @rebuildFloor float = 40;
    declare @schemaName sysname;
    declare @tableName  sysname;
    declare @indexName  sysname;
    declare @fragmentation float;
    declare @command nvarchar(500);

    print N'Начало перестроения индекса: ' + convert( nvarchar(100), SYSDATETIME(), 20 );
    print N'-------------------------------------------------------------------------';

    declare indexCursor cursor fast_forward local for
    select s.name schema_name, t.name table_name, i.name index_name, d.avg_fragmentation_in_percent fragmentation
    from   sys.dm_db_index_physical_stats( DB_ID(@databaseName), null, null, null, null) d
           inner join sys.tables  t on d.object_id = t.object_id
           inner join sys.schemas s on t.schema_id = s.schema_id
           inner join sys.indexes i on d.object_id = i.object_id AND d.index_id = i.index_id
    where  d.index_id > 0
           and d.avg_fragmentation_in_percent > 10
           and d.page_count > 8

    open indexCursor;

    while( 1=1 )
    begin
        fetch next from indexCursor into @schemaName, @tableName, @indexName, @fragmentation;
        if @@FETCH_STATUS <> 0 break;

        begin try
            set @command = N'ALTER INDEX ' + @indexName + N' ON ' + @databaseName + N'.' + @schemaName + N'.' + @tableName;
            if @fragmentation < @rebuildFloor
            begin
                set @command = @command + N' REORGANIZE;';
                set @command = @command + N' UPDATE STATISTICS ' + @databaseName + N'.' + @schemaName + N'.' + @tableName + N' ' + @indexName + N';';
            end
            else
            begin
                set @command = @command + N' REBUILD WITH (ONLINE = ON); ';
            end;
           
            --print @command;
            exec (@command);


            print N'INDEX ' + @indexName + N'ON ' + @databaseName + N'.' + @schemaName + N'.' + @tableName + N' Обработан';
        end try
        begin catch
            print N'ERROR REBUILD INDEX ' + @indexName;
            print N'ERROR MESSAGE: ' + ERROR_MESSAGE();
        end catch
    end;

    print N'-------------------------------------------------------------------------';
    print N'Перестроение индексов завершено: ' + convert( nvarchar(100), SYSDATETIME(), 20 );
    close indexCursor;
    deallocate indexCursor;
end;