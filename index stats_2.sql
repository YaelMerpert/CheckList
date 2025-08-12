

-- amount of allocated and unallocated space on per-database file basis

SELECT 
    f.type_desc as [Type]
    ,f.name as [FileName]
    ,fg.name as [FileGroup]
    ,f.physical_name as [Path]
    ,f.size / 128.0 as [CurrentSizeMB]
    ,f.size / 128.0 - convert(int,fileproperty(f.name,'SpaceUsed')) / 
        128.0 as [FreeSpaceMb]
FROM 
    sys.database_files f with (nolock) left outer join 
        sys.filegroups fg with (nolock) on
            f.data_space_id = fg.data_space_id
ORDER BY f.size DESC
option (recompile)


/*
###############################################################################################


		##    ## ######## ##     ## ########    ########     ###    ########  ######## 
		###   ## ##        ##   ##     ##       ##     ##   ## ##   ##     ##    ##    
		####  ## ##         ## ##      ##       ##     ##  ##   ##  ##     ##    ##    
		## ## ## ######      ###       ##       ########  ##     ## ########     ##    
		##  #### ##         ## ##      ##       ##        ######### ##   ##      ##    
		##   ### ##        ##   ##     ##       ##        ##     ## ##    ##     ##    
		##    ## ######## ##     ##    ##       ##        ##     ## ##     ##    ##    


#############################################################################################
 */
 
 -- information about space allocation on per-index basis in the database.



 ;with SpaceInfo(ObjectId, IndexId, TableName, IndexName
    ,Rows, TotalSpaceMB, UsedSpaceMB)
as
( 
    select  
        t.object_id as [ObjectId]
        ,i.index_id as [IndexId]
        ,s.name + '.' + t.Name as [TableName]
        ,i.name as [Index Name]
        ,sum(p.[Rows]) as [Rows]
        ,sum(au.total_pages) * 8 / 1024 as [Total Space MB]
        ,sum(au.used_pages) * 8 / 1024 as [Used Space MB]
    from    
        sys.tables t with (nolock) join 
            sys.schemas s with (nolock) on 
                s.schema_id = t.schema_id
            join sys.indexes i with (nolock) on 
                t.object_id = i.object_id
            join sys.partitions p with (nolock) on 
                i.object_id = p.object_id and 
                i.index_id = p.index_id
            cross apply
            (
                select 
                    sum(a.total_pages) as total_pages
                    ,sum(a.used_pages) as used_pages
                from sys.allocation_units a with (nolock)
                where p.partition_id = a.container_id 
            ) au
    where   
        i.object_id > 255
    group by
        t.object_id, i.index_id, s.name, t.name, i.name
)
select 
    ObjectId, IndexId, TableName, IndexName
    ,Rows, TotalSpaceMB, UsedSpaceMB
    ,TotalSpaceMB - UsedSpaceMB as [ReservedSpaceMB]
from 
    SpaceInfo		
order by
    TotalSpaceMB desc
option (recompile)

/*
###############################################################################################


		##    ## ######## ##     ## ########    ########     ###    ########  ######## 
		###   ## ##        ##   ##     ##       ##     ##   ## ##   ##     ##    ##    
		####  ## ##         ## ##      ##       ##     ##  ##   ##  ##     ##    ##    
		## ## ## ######      ###       ##       ########  ##     ## ########     ##    
		##  #### ##         ## ##      ##       ##        ######### ##   ##      ##    
		##   ### ##        ##   ##     ##       ##        ##     ## ##    ##     ##    
		##    ## ######## ##     ##    ##       ##        ##     ## ##     ##    ##    


#############################################################################################
 */
 
 --


	SELECT 
		index_id, partition_number, alloc_unit_type_desc
		,index_level, page_count, avg_page_space_used_in_percent
	FROM  
		sys.dm_db_index_physical_stats
		(
			db_id('DBName')						--Database
			,object_id(N'SchemaName.TableName')	-- Table (Object_ID)
			,1							-- Index ID
			,NULL						-- Partition ID – NULL – all partitions
			,'detailed'					-- Mode
		)



/*
###############################################################################################


		##    ## ######## ##     ## ########    ########     ###    ########  ######## 
		###   ## ##        ##   ##     ##       ##     ##   ## ##   ##     ##    ##    
		####  ## ##         ## ##      ##       ##     ##  ##   ##  ##     ##    ##    
		## ## ## ######      ###       ##       ########  ##     ## ########     ##    
		##  #### ##         ## ##      ##       ##        ######### ##   ##      ##    
		##   ### ##        ##   ##     ##       ##        ##     ## ##    ##     ##    
		##    ## ######## ##     ##    ##       ##        ##     ## ##     ##    ##    


#############################################################################################
 */
 
 

	SELECT  
		s.Name + N'.' + t.name as [Table]
		,i.name as [Index] 
		,i.is_unique as [IsUnique]
		,ius.user_seeks as [Seeks], ius.user_scans as [Scans]
		,ius.user_lookups as [Lookups]
		,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
		,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
		,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
		,ius.last_user_update as [Last Update]
	FROM  
		sys.tables t with (nolock) join sys.indexes i with (nolock) on
			t.object_id = i.object_id
		join sys.schemas s with (nolock) on 
			t.schema_id = s.schema_id
		left outer join sys.dm_db_index_usage_stats ius on
			ius.database_id = db_id() and
			ius.object_id = i.object_id and 
			ius.index_id = i.index_id
	--WHERE ius.user_updates > 0 and ius.user_seeks = 0 and ius.user_scans = 0 and ius.user_lookups = 0
	WHERE t.name = 'CargoControl_Cargo'
	order by
		s.name, t.name, i.index_id
	option (recompile)

	
	SELECT  
		s.Name + N'.' + t.name as [Table]
		,i.name as [Index] 
		,i.is_unique as [IsUnique]
		,ius.user_seeks as [Seeks], ius.user_scans as [Scans]
		,ius.user_lookups as [Lookups]
		,ius.user_seeks + ius.user_scans + ius.user_lookups as [Reads]
		,ius.user_updates as [Updates], ius.last_user_seek as [Last Seek]
		,ius.last_user_scan as [Last Scan], ius.last_user_lookup as [Last Lookup]
		,ius.last_user_update as [Last Update]
	FROM  
		sys.tables t with (nolock) join sys.indexes i with (nolock) on
			t.object_id = i.object_id
		join sys.schemas s with (nolock) on 
			t.schema_id = s.schema_id
		left outer join sys.dm_db_index_usage_stats ius on
			ius.database_id = db_id() and
			ius.object_id = i.object_id and 
			ius.index_id = i.index_id
	--WHERE ius.user_updates > 0 and ius.user_seeks = 0 and ius.user_scans = 0 and ius.user_lookups = 0
	WHERE t.name = 'DealFile_LeadDocument'
	order by
		s.name, t.name, i.index_id
	option (recompile)
	

/*
###############################################################################################


		##    ## ######## ##     ## ########    ########     ###    ########  ######## 
		###   ## ##        ##   ##     ##       ##     ##   ## ##   ##     ##    ##    
		####  ## ##         ## ##      ##       ##     ##  ##   ##  ##     ##    ##    
		## ## ## ######      ###       ##       ########  ##     ## ########     ##    
		##  #### ##         ## ##      ##       ##        ######### ##   ##      ##    
		##   ### ##        ##   ##     ##       ##        ##     ## ##    ##     ##    
		##    ## ######## ##     ##    ##       ##        ##     ## ##     ##    ##    


#############################################################################################
 */
 
 


	EXEC sp_spaceused N'SchemaName.TableName' 
	GO




	SELECT
		i.name                  AS IndexName,
		SUM(s.used_page_count) * 8   AS IndexSizeKB
	FROM sys.dm_db_partition_stats  AS s 
	JOIN sys.indexes                AS i
	ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
	WHERE s.[object_id] = object_id('SchemaName.TableName')
	GROUP BY i.name
	ORDER BY IndexSizeKB DESC

