USE MASTER;
GO
SET NOCOUNT ON;

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'SqlForensics')
BEGIN
	--RAISERROR ('Database SqlForensics Already Exists', 20, 1)  WITH LOG
	ALTER DATABASE [SqlForensics] 
	  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [SqlForensics];
END
CREATE DATABASE [SqlForensics];
GO

USE [SqlForensics];
GO

--EXEC sp_configure 'show advanced options', '1';
--RECONFIGURE
--GO

CREATE SCHEMA [ForensicLogging]; 

GO
CREATE TABLE [ForensicLogging].[Configuration] (
	[id] INTEGER IDENTITY,  
    [setting] VARCHAR (200),
    [value] VARCHAR (5000)
	);


CREATE TABLE [ForensicLogging].[Log] (
	[id] BIGINT IDENTITY(-9223372036854775808, 1),  
    [whenRecorded] DATETIME2 DEFAULT SYSDATETIME(),
	[typeId] SMALLINT NOT NULL,
    [itemId] INTEGER NOT NULL,
    [name] VARCHAR (5000),
    [value] VARCHAR (MAX)
	);


CREATE TABLE [ForensicLogging].[LogTypes] (
	[id] SMALLINT IDENTITY(-32768, 1),  
	[type] VARCHAR (50)
	);

GO
CREATE PROCEDURE [ForensicLogging].[monitorConfig] 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @logType as SMALLINT;
	SELECT @logType = lt.[id] 
	  FROM [ForensicLogging].[LogTypes] AS lt
	 WHERE lt.[type] = 'sys_configurations';

	IF(@logType is NULL)
	BEGIN
		INSERT INTO [ForensicLogging].[LogTypes]([type])
			 VALUES ('sys_configurations');

		SELECT @logType = lt.[id] 
		  FROM [ForensicLogging].[LogTypes] AS lt
		 WHERE lt.[type] = 'sys_configurations';
	END

	IF(@logType is not NULL)
	BEGIN

		;WITH wrapperCte 
		AS( 
			SELECT itemId, name, value, whenRecorded,
				   ROW_NUMBER() OVER (PARTITION BY typeId, itemId ORDER BY ID DESC) as sorter
			FROM [ForensicLogging].[Log]
			WHERE typeId = @logType
		),
		existingCte 
		AS(
			SELECT * 
			 FROM wrapperCte
			 WHERE sorter = 1
		)
		,currentCTE
		AS
		(
			SELECT c.CONFIGURATION_ID as itemId, c.NAME as name, cast(c.VALUE AS VARCHAR(100)) + '/' + cast(c.VALUE_IN_USE as VARCHAR(100)) as VALUE 
				FROM sys.configurations as c
		)
		INSERT INTO [ForensicLogging].[Log] ([typeId], [itemId], [name], [value]) 
		SELECT @logType, c.*
		  FROM currentCTE as c
		  LEFT JOIN existingCTE as e ON e.itemId = c.itemId AND e.name = c.name AND c.value = e.value
		WHERE e.value is NULL;
	END
END
GO
CREATE PROCEDURE [ForensicLogging].[runFullMonitoringPass] 
AS
BEGIN
	SET NOCOUNT ON;
	EXECUTE [ForensicLogging].[monitorConfig];
END
GO


EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
EXEC sp_configure 'show advanced options', '1';
 WAITFOR DELAY '00:00:02';
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
EXEC sp_configure 'show advanced options', '0';
 WAITFOR DELAY '00:00:02';
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;



SELECT * 
  FROM [ForensicLogging].[Log]

