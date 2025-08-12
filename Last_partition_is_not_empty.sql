SET NOCOUNT, XACT_ABORT, ARITHABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF SERVERPROPERTY('EngineEdition') IN (3,5,6,8) -- Enterprise equivalent
OR (CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff) > 13) -- SQL 2017+
OR (CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff) = 13 AND CONVERT(int, @@microsoftversion & 0xffff) >= 4001) -- SQL 2016 SP1+
BEGIN
    SET NOCOUNT ON;
    DECLARE @Results AS TABLE
    (database_id INT, object_id INT, rows INT, partition_number INT, partition_scheme SYSNAME, last_boundary_range SQL_VARIANT);

    INSERT INTO @Results
    EXEC sp_MSforeachdb 'IF DATABASEPROPERTYEX(''?'', ''Status'') = ''ONLINE'' AND DATABASEPROPERTYEX(''?'', ''Updateability'') = ''READ_WRITE''
BEGIN
    USE [?];
    SELECT DB_ID(), t.object_id, p.rows, p.partition_number, p.partition_scheme, p.last_boundary_range
    FROM sys.tables AS t
    CROSS APPLY
    (
    SELECT TOP 1 p.rows, p.partition_number, ps.name AS partition_scheme, last_range.value AS last_boundary_range
    FROM sys.partitions AS p
 INNER JOIN sys.indexes AS ix ON p.object_id = ix.object_id AND p.index_id = ix.index_id
 INNER JOIN sys.partition_schemes AS ps ON ix.data_space_id = ps.data_space_id
 CROSS APPLY
 (
 SELECT TOP 1 *
 FROM sys.partition_range_values AS pr
 WHERE pr.function_id = ps.function_id
 ORDER BY pr.boundary_id DESC
 ) AS last_range
    WHERE p.partition_number > 1 -- non-first partition
    AND p.index_id <= 1 -- clustered or heap only
    AND p.object_id = t.object_id
    ORDER BY partition_number DESC
    ) AS p
    WHERE t.is_ms_shipped = 0
    AND p.rows > 0
END'

    SELECT
    MessageText = N'In Server: ' + @@SERVERNAME + N', Database: ' + QUOTENAME(DB_NAME(database_id))
    + N', Table: ' + QUOTENAME(OBJECT_SCHEMA_NAME(object_id, database_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id, database_id))
    + N' last partition "' + CONVERT(nvarchar(4000), partition_number) + N'" is not empty'
 + ISNULL(N' (boundary range "' + CONVERT(nvarchar(4000), last_boundary_range, 21) + N'" in partition scheme ' + QUOTENAME(partition_scheme) + N')'
  , N'')
    , [rows]
    FROM @Results
END
ELSE
    SELECT N'Table partitioning not supported on this instance. Check skipped.', 0


---AWS

SET NOCOUNT, XACT_ABORT, ARITHABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF SERVERPROPERTY('EngineEdition') IN (3,5,6,8) -- Enterprise equivalent
OR (CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff) > 13) -- SQL 2017+
OR (CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff) = 13 AND CONVERT(int, @@microsoftversion & 0xffff) >= 4001) -- SQL 2016 SP1+
BEGIN
    SET NOCOUNT ON;
    DECLARE @Results AS TABLE
    (database_id INT, object_id INT, rows INT, partition_number INT, partition_scheme SYSNAME, last_boundary_range SQL_VARIANT);

    INSERT INTO @Results
    EXEC sp_MSforeachdb 'IF DATABASEPROPERTYEX(''?'', ''Status'') = ''ONLINE'' AND DATABASEPROPERTYEX(''?'', ''Updateability'') = ''READ_WRITE''
BEGIN
    USE [?];
    SELECT DB_ID(), t.object_id, p.rows, p.partition_number, p.partition_scheme, p.last_boundary_range
    FROM sys.tables AS t
    CROSS APPLY
    (
    SELECT TOP 1 p.rows, p.partition_number, ps.name AS partition_scheme, last_range.value AS last_boundary_range
    FROM sys.partitions AS p
 INNER JOIN sys.indexes AS ix ON p.object_id = ix.object_id AND p.index_id = ix.index_id
 INNER JOIN sys.partition_schemes AS ps ON ix.data_space_id = ps.data_space_id
 CROSS APPLY
 (
 SELECT TOP 1 *
 FROM sys.partition_range_values AS pr
 WHERE pr.function_id = ps.function_id
 ORDER BY pr.boundary_id DESC
 ) AS last_range
    WHERE p.partition_number > 1 -- non-first partition
    AND p.index_id <= 1 -- clustered or heap only
    AND p.object_id = t.object_id
    ORDER BY partition_number DESC
    ) AS p
    WHERE t.is_ms_shipped = 0
    AND p.rows > 0
END'

    SELECT
    MessageText = N'In Server: ' + @@SERVERNAME + N', Database: ' + QUOTENAME(DB_NAME(database_id))
    + N', Table: ' + QUOTENAME(OBJECT_SCHEMA_NAME(object_id, database_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id, database_id))
    + N' last partition "' + CONVERT(nvarchar(4000), partition_number) + N'" is not empty'
 + ISNULL(N' (boundary range "' + CONVERT(nvarchar(4000), last_boundary_range, 21) + N'" in partition scheme ' + QUOTENAME(partition_scheme) + N')'
  , N'')
    , [rows]
    FROM @Results
END
ELSE
    SELECT N'Table partitioning not supported on this instance. Check skipped.', 0



	---AZURE

	SET NOCOUNT, XACT_ABORT, ARITHABORT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
MessageText = N'In Server: ' + @@SERVERNAME + N', Database: ' + QUOTENAME(DB_NAME())
+ N', Table: ' + QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id))
+ N' last partition "' + CONVERT(nvarchar(4000), partition_number) + N'" is not empty'
+ ISNULL(N' (boundary range "' + CONVERT(nvarchar(4000), last_boundary_range, 21) + N'" in partition scheme ' + QUOTENAME(partition_scheme) + N')'
, N'')
, [rows]
FROM (
SELECT t.object_id, p.rows, p.partition_number, p.partition_scheme, p.last_boundary_range
FROM sys.tables AS t
CROSS APPLY
(
SELECT TOP 1 p.rows, p.partition_number, ps.name AS partition_scheme, last_range.value AS last_boundary_range
FROM sys.partitions AS p
INNER JOIN sys.indexes AS ix ON p.object_id = ix.object_id AND p.index_id = ix.index_id
INNER JOIN sys.partition_schemes AS ps ON ix.data_space_id = ps.data_space_id
CROSS APPLY
(
SELECT TOP 1 *
FROM sys.partition_range_values AS pr
WHERE pr.function_id = ps.function_id
ORDER BY pr.boundary_id DESC
) AS last_range
WHERE p.partition_number > 1 -- non-first partition
AND p.index_id <= 1 -- clustered or heap only
AND p.object_id = t.object_id
ORDER BY partition_number DESC
) AS p
WHERE t.is_ms_shipped = 0
AND p.rows > 0
) AS r
