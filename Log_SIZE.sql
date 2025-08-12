DROP TABLE IF EXISTS #TempForLogSpace;
GO
CREATE TABLE #TempForLogSpace
	(
		[Database Name] VARCHAR(32)
	  , [Log Size (MB)] REAL
	  , [Log Space Used (%)] REAL
	  , Status INT
	);
DECLARE @sql_command NVARCHAR(100) = N'';
SELECT @sql_command = N'dbcc sqlperf (logspace)';
INSERT INTO #TempForLogSpace
EXEC (@sql_command);


SELECT [Database Name]
	 , ([Log Size (MB)] / 1024) AS [Log Size (GB)]
	 , [Log Space Used (%)]
	 , Status
FROM #TempForLogSpace
ORDER BY [Log Size (GB)] DESC;
--ORDER BY [Log Space Used (%)] DESC