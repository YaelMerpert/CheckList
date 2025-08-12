
DECLARE @From DATETIME = CAST(GETDATE () - 1 AS DATE);
DECLARE @To DATETIME = DATEADD ( SECOND, 86399, @From );


EXECUTE Maintenance.[_Admin_].[usp_Maintenance_GetTimeOutInfo_Full] 
		@AlertTimeStart = @From
		, @AlertTimeEnd = @To
--		, @ObjectName = N''					   -- nvarchar(255)

