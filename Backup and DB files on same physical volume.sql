SET NOCOUNT, ARITHABORT, XACT_ABORT, QUOTED_IDENTIFIER ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#RecentBackups') IS NOT NULL DROP TABLE #RecentBackups;
CREATE TABLE #RecentBackups (ID INT PRIMARY KEY NONCLUSTERED IDENTITY(1,1), PhysicalPath NVARCHAR(4000), DeviceName NVARCHAR(4000), DBFilesCount INT NULL);
CREATE CLUSTERED INDEX IX_Device ON #RecentBackups (DeviceName ASC);

DECLARE @CurrID INT, @CurrFile NVARCHAR(4000), @DBFilesCount INT, @Exists INT;
 
INSERT INTO #RecentBackups(PhysicalPath, DeviceName)
SELECT DISTINCT physical_device_name, UPPER(SUBSTRING(physical_device_name, 0, CHARINDEX('\', physical_device_name, 3)))
FROM msdb.dbo.backupmediafamily AS bmf
INNER JOIN msdb.dbo.backupset AS bs
ON bmf.media_set_id = bs.media_set_id
AND physical_device_name IS NOT NULL
 
DECLARE Backups CURSOR LOCAL FAST_FORWARD FOR
SELECT bmf.ID, bmf.PhysicalPath, dbfiles.numOfFiles
FROM #RecentBackups AS bmf
CROSS APPLY
(
SELECT COUNT(*) AS numOfFiles
FROM sys.master_files AS mf
WHERE [database_id] NOT IN (1,3,32767)
AND UPPER(SUBSTRING(physical_name, 0, CHARINDEX('\', physical_name, 3))) = bmf.DeviceName
) AS dbfiles
WHERE dbfiles.numOfFiles > 0
 
OPEN Backups
FETCH NEXT FROM Backups INTO @CurrID, @CurrFile, @DBFilesCount
 
WHILE @@FETCH_STATUS = 0
BEGIN
 SET @Exists = 1;
 EXEC master.dbo.xp_fileexist @CurrFile, @Exists out;
 
 IF @Exists = 0
  DELETE FROM #RecentBackups WHERE ID = @CurrID;
 ELSE
  UPDATE #RecentBackups SET DBFilesCount = @DBFilesCount WHERE ID = @CurrID;
 
 FETCH NEXT FROM Backups INTO @CurrID, @CurrFile, @DBFilesCount
END
 
CLOSE Backups
DEALLOCATE Backups

IF (SELECT SUM(DBFilesCount) FROM #RecentBackups) > 10
AND (SELECT COUNT(DISTINCT PhysicalPath) FROM #RecentBackups) <= 10
BEGIN
 SELECT N'In server ' + @@SERVERNAME + N': Volume "' + DeviceName + N'" contains backup file "'
  + bmf.PhysicalPath + N'" and '
  + CONVERT(nvarchar(4000), COUNT(DISTINCT mf.physical_name)) + N' database file(s).'
 , bmf.DBFilesCount
 FROM #RecentBackups AS bmf
 INNER JOIN sys.master_files AS mf
 ON UPPER(SUBSTRING(physical_name, 0, CHARINDEX('\', physical_name, 3))) = DeviceName
 WHERE [database_id] NOT IN (1,3,32767)
 GROUP BY DeviceName, bmf.PhysicalPath, bmf.DBFilesCount
END
ELSE IF (SELECT SUM(DBFilesCount) FROM #RecentBackups) <= 10
BEGIN
 SELECT DISTINCT N'In server ' + @@SERVERNAME + N': Volume "' + DeviceName + N'" contains backup file "'
  + bmf.PhysicalPath + N'" as well as database file "' + mf.physical_name + N'" belonging to database "' + DB_NAME(mf.database_id) + N'".'
 , bmf.DBFilesCount
 FROM #RecentBackups AS bmf
 INNER JOIN sys.master_files AS mf
 ON UPPER(SUBSTRING(physical_name, 0, CHARINDEX('\', physical_name, 3))) = DeviceName
 WHERE [database_id] NOT IN (1,3,32767)
END
ELSE
BEGIN
 SELECT N'In server ' + @@SERVERNAME + N': Volume "' + DeviceName + N'" contains '
  + CONVERT(nvarchar(4000), COUNT(DISTINCT bmf.PhysicalPath)) + N' backup file(s) and '
  + CONVERT(nvarchar(4000), COUNT(DISTINCT mf.physical_name)) + N' database file(s).'
 , 1
 FROM #RecentBackups AS bmf
 INNER JOIN sys.master_files AS mf
 ON UPPER(SUBSTRING(physical_name, 0, CHARINDEX('\', physical_name, 3))) = DeviceName
 WHERE [database_id] NOT IN (1,3,32767)
 GROUP BY DeviceName
END
