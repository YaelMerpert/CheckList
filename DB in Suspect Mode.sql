--DB in Suspect Mode
EXEC sp_resetstatus [AdventureWorks2016CTP3];
ALTER DATABASE  [AdventureWorks2016CTP3] SET EMERGENCY
DBCC checkdb( [AdventureWorks2016CTP3])
ALTER DATABASE  [AdventureWorks2016CTP3] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CheckDB ( [AdventureWorks2016CTP3], REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE  [AdventureWorks2016CTP3] SET MULTI_USER



/*#######################################################################################################*/

--Also

/*#######################################################################################################*/





USE [master]
GO
ALTER DATABASE [MyDatabase] SET EMERGENCY
GO
ALTER DATABASE [MyDatabase] SET SINGLE_USER
GO
DBCC CHECKDB ([MyDatabase], REPAIR_ALLOW_DATA_LOSS)
GO
ALTER DATABASE [MyDatabase] SET MULTI_USER
GO
ALTER DATABASE [MyDatabase] SET ONLINE
GO