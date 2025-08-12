set nocount on 

declare @string  nvarchar(4000)
declare @dbinfo_table table
				(ParentObject  varchar(255),
                  Object        varchar(255),
                   Field         varchar(255),
                   value         varchar(255))

SET @string = 'DBCC DBINFO(' + DB_NAME() + ') WITH TABLERESULTS, NO_INFOMSGS'
INSERT INTO @dbinfo_table EXEC(@string)

--The logic below is because read only databases don't update system pages when running DBCC CHECKDB and so, are not reported in DBCC DBINFO().
IF EXISTS (SELECT 1 FROM sys.databases d WHERE d.database_id = DB_ID() AND d.is_read_only = 1)
BEGIN
	DECLARE @TmpErrorLog TABLE 
	(
		[Number] INT NULL,
		[Date] DATETIME NULL,
		[LogFileSize] INT NULL 
	);

	DECLARE @ErrorLog TABLE 
	(
		[LogDate] DATETIME NULL,
		[ProcessInfo] varchar(20) NULL,
		[Text] varchar(4000) 
	);

	INSERT INTO @TmpErrorLog ([Number], [Date], [LogFileSize])
	EXEC [master].[dbo].xp_enumerrorlogs ;

	DECLARE @LogFileSize float,
		@Number smallint,
		@DaysOld tinyint = 0,
		@SearchString varchar(100),
		@LogDate datetime,
		@CollectFiles bit = 1;

	SET @SearchString = 'DBCC CHECKDB (' + DB_NAME() + ') executed by'
	
	SELECT TOP 1 @DaysOld = DATEDIFF(dd, [Date], GETDATE()), @Number = Number, @LogFileSize = LogFileSize / 1024 / 1024 FROM @TmpErrorLog ORDER BY [Number]
	DELETE FROM @TmpErrorLog WHERE number = (SELECT TOP 1 number FROM @TmpErrorLog ORDER BY [Number])

	WHILE @DaysOld < 7 --Only check the last 7 days
	BEGIN
		
		IF @LogFileSize < 300 --As optimization we only look in files smaller than 300MB
		BEGIN
			INSERT INTO @ErrorLog
			--EXEC sp_readerrorlog 1, 1, @SearchString --Fixed
			EXEC sp_readerrorlog @Number, 1, @SearchString

			SELECT @LogDate = MAX(LogDate) FROM @ErrorLog

			IF @LogDate IS NOT NULL
				UPDATE @dbinfo_table
				SET value = CONVERT(varchar(50), @LogDate, 121) 
				WHERE Field = 'dbi_dbccLastKnownGood'

			SET @DaysOld = NULL
			SELECT TOP 1 @DaysOld = DATEDIFF(dd, [Date], GETDATE()), @Number = Number, @LogFileSize = LogFileSize / 1024 / 1024 FROM @TmpErrorLog ORDER BY [Number]
			DELETE FROM @TmpErrorLog WHERE number = (SELECT TOP 1 number FROM @TmpErrorLog ORDER BY [Number])
		END
	END
END

--Return the collected information
select * from @dbinfo_table;