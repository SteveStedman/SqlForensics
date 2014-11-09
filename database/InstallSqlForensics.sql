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
    [itemId] BIGINT NOT NULL,
    [value] VARCHAR (MAX)
	);

CREATE TABLE [ForensicLogging].[LogTypes] (
	[id] SMALLINT IDENTITY(-32768, 1),  
	[type] VARCHAR (50)
	);

CREATE TABLE [ForensicLogging].[LogItems] (
	[id] BIGINT IDENTITY(-9223372036854775808, 1),
	[theItemsId] INTEGER NOT NULL,
    [name] VARCHAR (5000),
	);
GO

CREATE PROCEDURE [ForensicLogging].[getLogTypeId]
	@type VARCHAR (50)
AS
BEGIN	
	DECLARE @logType as SMALLINT;

	SELECT @logType = lt.[id] 
	  FROM [ForensicLogging].[LogTypes] AS lt
	 WHERE lt.[type] = @type;

	IF(@logType is NULL)
	BEGIN
		INSERT INTO [ForensicLogging].[LogTypes]([type])
			 VALUES (@type);

		SELECT @logType = lt.[id] 
		  FROM [ForensicLogging].[LogTypes] AS lt
		 WHERE lt.[type] = @type;
	END

	RETURN @logType;
END
GO
CREATE PROCEDURE [ForensicLogging].[monitorConfig] 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @logTypeId as SMALLINT;
	DECLARE @type varchar(50);
	SET @type = 'sys_configurations';

	EXECUTE @logTypeId = [ForensicLogging].[getLogTypeId] @type;
	IF(@logTypeId is not NULL)
	BEGIN

		MERGE [ForensicLogging].[LogItems]  AS target       
		USING (SELECT configuration_id, name  FROM sys.configurations as c) AS source (theItemsId, name)       
		ON (target.theItemsId = source.theItemsId and target.name = source.name)   
		WHEN NOT MATCHED THEN                                 
		INSERT (theItemsId, name)                                 
		VALUES (source.theItemsId, source.name);  


		;WITH wrapperCte 
		AS( 
			SELECT [itemId], [value], 
				   ROW_NUMBER() OVER (PARTITION BY [typeId], [itemId] ORDER BY ID DESC) as sorter
			  FROM [ForensicLogging].[Log]
			 WHERE [typeId] = @logTypeId
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
			SELECT l.id as itemId, cast(c.VALUE AS VARCHAR(100)) + '/' + cast(c.VALUE_IN_USE as VARCHAR(100)) as VALUE 
			  FROM sys.configurations as c
			 INNER JOIN [ForensicLogging].[LogItems] as l ON l.theItemsId = c.CONFIGURATION_ID AND l.name = c.NAME
		)
		INSERT INTO [ForensicLogging].[Log] ([typeId], [itemId], [value]) 
		SELECT @logTypeId, c.*
		  FROM currentCTE as c
		  LEFT JOIN existingCTE as e ON e.itemId = c.itemId AND c.value = e.value
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

EXEC sp_configure 'show advanced options', '0';

EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
EXEC sp_configure 'show advanced options', '1';
 WAITFOR DELAY '00:00:02';
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
EXEC sp_configure 'show advanced options', '0';
 WAITFOR DELAY '00:00:02';
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
EXEC sp_configure 'show advanced options', '1';
 WAITFOR DELAY '00:00:02';
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;



SELECT li.[name], l.[whenRecorded], l.[value]
  FROM [ForensicLogging].[Log] l
  INNER JOIN [ForensicLogging].[LogItems]  li on li.[id] = l.[itemId]
  ORDER BY [whenRecorded] DESC;



