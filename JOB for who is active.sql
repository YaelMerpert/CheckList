---1---

CREATE TABLE #sp_who2 
(
   SPID INT,  
   Status VARCHAR(250) NULL,  
   Login SYSNAME NULL,  
   HostName SYSNAME NULL,  
   BlkBy SYSNAME NULL,  
   DBName SYSNAME NULL,  
   Command VARCHAR(250) NULL,  
   CPUTime INT NULL,  
   DiskIO INT NULL,  
   LastBatch VARCHAR(250) NULL,  
   ProgramName VARCHAR(250) NULL,  
   SPID2 INT NULL,
   REQUESTID INT NULL
) 
GO

--2--

INSERT INTO #sp_who2 EXEC sp_who2
GO

--3--

SELECT * FROM #sp_who2
WHERE       DBName <> 'master'
ORDER BY    DBName ASC
GO
-- 4 ---
DROP TABLE #sp_who2
GO
