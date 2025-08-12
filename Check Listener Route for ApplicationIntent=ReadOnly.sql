

--Change Linkedserver / LinkedserverReadOnly / ListenerName/ DatabaseName to Proper names

USE [master]
GO


EXEC master.dbo.sp_addlinkedserver @server = N'Linkedserver', @srvproduct=N'SqlServer', @provider=N'SQLNCLI', @datasrc=N'ListenerName.mdev.com', @catalog=N'DatabaseName'

EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'CUSTOMS',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'CUSTOMS',@useself=N'False',@locallogin=N'sa',@rmtuser=N'LinkedServer_Reader',@rmtpassword='########'
GO



USE [master]
GO


EXEC master.dbo.sp_addlinkedserver @server = N'LinkedserverReadOnly', @srvproduct=N'SqlServer', @provider=N'SQLNCLI', @datasrc=N'ListenerName.mdev.com', @provstr=N'ApplicationIntent=ReadOnly', @catalog=N'DatabaseName'

EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'CUSTOMSRO',@useself=N'False',@locallogin=NULL,@rmtuser=N'LinkedServer_Reader',@rmtpassword='########'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'CUSTOMSRO',@useself=N'False',@locallogin=N'sa',@rmtuser=N'LinkedServer_Reader',@rmtpassword='########'
GO