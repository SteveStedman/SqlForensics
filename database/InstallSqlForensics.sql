
-- For Information on Optional Settings see the Wiki at 
--    https://github.com/SteveStedman/SqlForensics/wiki/OptionalSettings


USE MASTER;
GO
SET NOCOUNT ON;

IF EXISTS(SELECT sd.[name] FROM sys.databases AS sd WHERE sd.[name] = 'SqlForensics')
BEGIN
	--RAISERROR ('Database SqlForensics Already Exists', 20, 1)  WITH LOG
	-- comment out the RAISEERROR line above and uncomment the following three lines if you
	--   are running the script a second time. 
	   
	ALTER DATABASE [SqlForensics] 
	  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [SqlForensics];
END

-- NOTE set to Case Sensitive for testing purpose. The COLLATE line can certainly be removed or changed as needed.
CREATE DATABASE [SqlForensics]
COLLATE SQL_Latin1_General_CP1_CS_AS;
GO

USE [SqlForensics];
GO

CREATE SCHEMA [ForensicLogging]; 
GO
CREATE TABLE [ForensicLogging].[Configuration] (
	[id] INTEGER IDENTITY,  
    [setting] NVARCHAR (200),
    [value] NVARCHAR (4000)
	);

GO
CREATE TABLE [ForensicLogging].[LogTypes](
	[id] [SMALLINT] IDENTITY(-32768,1) NOT NULL,
	[type] [NVARCHAR](50) NULL,
 CONSTRAINT [PK_LogTypes] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE [ForensicLogging].[LogItems](
	[id] [bigint] IDENTITY(-9223372036854775808,1) NOT NULL,
	[theItemsId] [INTEGER] NULL,
	[name] [NVARCHAR](4000) NULL,
 CONSTRAINT [PK_LogItems] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ForensicLogging].[databaseAndServer](
	[id] [bigint] IDENTITY(-9223372036854775808,1) NOT NULL,
	[databaseName] [NVARCHAR](1000) NULL,
	[serverName] [NVARCHAR](1000) NULL,
 CONSTRAINT [PK_databaseAndServer] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [ForensicLogging].[Log](
	[id] [bigint] IDENTITY(-9223372036854775808,1) NOT NULL,
	[whenRecorded] [datetime2](7) NULL,
	[databaseServerId] bigint NOT NULL, 
	[typeId] [smallint] NOT NULL,
	[itemId] [bigint] NOT NULL,
	[value] [NVARCHAR](max) NULL,
 CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO

ALTER TABLE [ForensicLogging].[Log] ADD  DEFAULT (sysdatetime()) FOR [whenRecorded];
GO

ALTER TABLE [ForensicLogging].[Log]  WITH CHECK ADD  CONSTRAINT [FK_Log_LogItems] FOREIGN KEY([itemId])
REFERENCES [ForensicLogging].[LogItems] ([id]);
GO

ALTER TABLE [ForensicLogging].[Log] CHECK CONSTRAINT [FK_Log_LogItems];
GO

ALTER TABLE [ForensicLogging].[Log]  WITH CHECK ADD  CONSTRAINT [FK_Log_databaseAndServer] FOREIGN KEY([databaseServerId])
REFERENCES [ForensicLogging].[databaseAndServer] ([id]);
GO

ALTER TABLE [ForensicLogging].[Log] CHECK CONSTRAINT [FK_Log_databaseAndServer];
GO

ALTER TABLE [ForensicLogging].[Log]  WITH CHECK ADD  CONSTRAINT [FK_Log_LogTypes] FOREIGN KEY([typeId])
REFERENCES [ForensicLogging].[LogTypes] ([id]);
GO

ALTER TABLE [ForensicLogging].[Log] CHECK CONSTRAINT [FK_Log_LogTypes];
GO

CREATE PROCEDURE [ForensicLogging].[getLogTypeId]
	@type NVARCHAR (50)
AS
BEGIN	
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/FunctionsAndProcedures
	DECLARE @logType AS SMALLINT;

	SELECT @logType = lt.[id] 
	  FROM [ForensicLogging].[LogTypes] AS lt
	 WHERE lt.[type] = @type;

	IF(@logType IS NULL)
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
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/FunctionsAndProcedures
	SET NOCOUNT ON;
	DECLARE @databaseAndServerId AS BIGINT;
	DECLARE @logTypeId AS SMALLINT;
	DECLARE @type NVARCHAR(50);
	SET @type = 'sys_configurations';
	SET @databaseAndServerId = NULL;

	EXECUTE @logTypeId = [ForensicLogging].[getLogTypeId] @type;
	IF(@logTypeId IS NOT NULL)
	BEGIN
		MERGE [ForensicLogging].[LogItems]  AS target       
		USING (SELECT configuration_id, name  FROM sys.configurations AS c) AS source (theItemsId, name)       
		   ON (target.theItemsId = source.theItemsId AND 
			   target.name COLLATE DATABASE_DEFAULT = source.name COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (theItemsId, name)                                 
	   VALUES (source.theItemsId, source.name);  

		MERGE [ForensicLogging].[databaseAndServer]  AS target       
		USING (SELECT @@SERVERNAME, '') AS source (serverName, databaseName)       
		   ON (target.databaseName COLLATE DATABASE_DEFAULT = source.databaseName COLLATE DATABASE_DEFAULT AND 
			   target.serverName COLLATE DATABASE_DEFAULT = source.serverName COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (serverName, databaseName)                                 
	   VALUES (source.serverName, source.databaseName);  

	   SELECT @databaseAndServerId =  das.[id]
	     FROM [ForensicLogging].[databaseAndServer] AS das
		WHERE das.[databaseName] COLLATE DATABASE_DEFAULT = '' 
		  AND  das.[serverName] COLLATE DATABASE_DEFAULT = @@SERVERNAME;   

		;WITH wrapperCTE AS
		( 
			SELECT l.[itemId], l.[value], 
				   ROW_NUMBER() OVER (PARTITION BY l.[typeId], l.[itemId] ORDER BY l.[id] DESC) AS sorter
			  FROM [ForensicLogging].[Log] AS l
			 WHERE l.[typeId] = @logTypeId
		),existingCTE AS
		(
			SELECT cte.[itemId], cte.[value] 
			  FROM wrapperCTE as cte
			 WHERE cte.[sorter] = 1
		),currentCTE	AS
		(
			SELECT l.id AS itemId, 
			       cast(c.VALUE AS NVARCHAR(100)) + '/' + cast(c.VALUE_IN_USE AS NVARCHAR(100)) AS value
			  FROM sys.configurations AS c
			 INNER JOIN [ForensicLogging].[LogItems] AS l 
			         ON l.theItemsId = c.CONFIGURATION_ID AND 
					    l.name COLLATE DATABASE_DEFAULT = c.NAME COLLATE DATABASE_DEFAULT 
		)
		INSERT INTO [ForensicLogging].[Log] ([typeId], [itemId], [value], [databaseServerId]) 
		SELECT @logTypeId, c.*, @databaseAndServerId
		  FROM currentCTE AS c
		  LEFT JOIN existingCTE AS e ON e.[itemId] = c.[itemId] AND c.[value] = e.[value]
		 WHERE e.[value] IS NULL;
	END
END
GO
CREATE PROCEDURE [ForensicLogging].[monitorUsers] 
AS
BEGIN
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/FunctionsAndProcedures
	SET NOCOUNT ON;
	DECLARE @databaseAndServerId AS BIGINT;
	DECLARE @logTypeId AS SMALLINT;
	DECLARE @type [NVARCHAR](50);
	SET @type = 'users';
	SET @databaseAndServerId = NULL;

	EXECUTE @logTypeId = [ForensicLogging].[getLogTypeId] @type;
	IF(@logTypeId IS NOT NULL)
	BEGIN
		CREATE TABLE #tempUsers (
			loginName NVARCHAR(max),
			dbName NVARCHAR(max),
			userName NVARCHAR(max), 
			aliasName NVARCHAR(max)
		);

		INSERT INTO #tempUsers
		EXEC master..sp_msloginmappings;

		MERGE [ForensicLogging].[LogItems]  AS target       
		USING (SELECT ISNULL(loginName, '') + '/' + ISNULL(userName, '') FROM #tempUsers) AS source (name)       
		   ON (target.name COLLATE DATABASE_DEFAULT = source.name COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (name)                                 
	   VALUES (source.name);  

		MERGE [ForensicLogging].[databaseAndServer]  AS target       
		USING (SELECT DISTINCT @@SERVERNAME, dbName FROM #tempUsers WHERE dbName IS NOT NULL) AS source (serverName, databaseName)       
		   ON (target.databaseName COLLATE DATABASE_DEFAULT = source.databaseName COLLATE DATABASE_DEFAULT AND 
			   target.serverName COLLATE DATABASE_DEFAULT = source.serverName COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (serverName, databaseName)                                 
	   VALUES (source.serverName, source.databaseName);  

		;WITH wrapperCTE AS
		( 
			SELECT l.[itemId], l.[value], 
				   ROW_NUMBER() OVER (PARTITION BY l.[typeId], l.[itemId] ORDER BY l.[id] DESC) AS sorter
			  FROM [ForensicLogging].[Log] AS l
			 WHERE l.[typeId] = @logTypeId
		),existingCTE AS
		(
			SELECT cte.[itemId], cte.[value]
			  FROM wrapperCTE as cte
			 WHERE cte.[sorter] = 1
		),currentCTE	AS
		(
			SELECT l.id AS itemId, ISNULL(tu.loginName, '') + '/' + ISNULL(tu.userName, '') AS value, das.id AS databaseServerId
			  FROM #tempUsers tu
			 INNER JOIN [ForensicLogging].[LogItems] AS l 
			        ON l.theItemsId IS NULL AND 
					   l.name COLLATE DATABASE_DEFAULT = ISNULL(tu.loginName, '') + '/' + ISNULL(tu.userName, '') COLLATE DATABASE_DEFAULT  
			 INNER JOIN [ForensicLogging].[databaseAndServer]  AS das
			        ON das.databaseName COLLATE DATABASE_DEFAULT = tu.dbName COLLATE DATABASE_DEFAULT 
					AND das.serverName COLLATE DATABASE_DEFAULT = @@SERVERNAME COLLATE DATABASE_DEFAULT 
		)
		INSERT INTO [ForensicLogging].[Log] ([typeId], [itemId], [value], [databaseServerId]) 
		SELECT @logTypeId, c.*
		  FROM currentCTE AS c
		  LEFT JOIN existingCTE AS e ON e.[itemId] = c.[itemId] 
		      AND c.[value] COLLATE DATABASE_DEFAULT = e.[value] COLLATE DATABASE_DEFAULT 
		 WHERE e.[value] IS NULL;

		DROP TABLE #tempUsers;
	END	
END
GO
CREATE PROCEDURE [ForensicLogging].[monitorObjects] 
AS
BEGIN
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/FunctionsAndProcedures
	SET NOCOUNT ON;
	DECLARE @databaseAndServerId AS BIGINT;
	DECLARE @logTypeId AS SMALLINT;
	DECLARE @type [NVARCHAR](50);
	SET @type = 'objects';
	SET @databaseAndServerId = NULL;
	EXECUTE @logTypeId = [ForensicLogging].[getLogTypeId] @type;
	IF(@logTypeId IS NOT NULL)
	BEGIN
		CREATE TABLE #tempOutput (
					itemName NVARCHAR(max),
					dbName NVARCHAR(max),
					itemId INTEGER, 
					itemDetails NVARCHAR(max)
				);

		INSERT INTO #tempOutput
		EXECUTE master.sys.sp_MSforeachdb '
					SELECT  ''[?].['' + s.name + ''].['' + o.name + '']'' RoutineName,
							''?'',
							procs.object_id,
							procs.[definition]
		
					FROM    [?].sys.sql_modules procs
					INNER JOIN [?].sys.objects o ON procs.object_id = o.object_id
					INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id';

		MERGE [ForensicLogging].[LogItems]  AS target       
		USING (SELECT itemName FROM #tempOutput) AS source (name)       
		   ON (target.name COLLATE DATABASE_DEFAULT = source.name COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (name)                                 
	   VALUES (source.name);  

		MERGE [ForensicLogging].[databaseAndServer]  AS target       
		USING (SELECT DISTINCT @@SERVERNAME, dbName FROM #tempOutput WHERE dbName IS NOT NULL) AS source (serverName, databaseName)       
		   ON (target.databaseName COLLATE DATABASE_DEFAULT = source.databaseName COLLATE DATABASE_DEFAULT AND 
			   target.serverName COLLATE DATABASE_DEFAULT = source.serverName COLLATE DATABASE_DEFAULT)   
		 WHEN NOT MATCHED THEN                                 
	   INSERT (serverName, databaseName)                                 
	   VALUES (source.serverName, source.databaseName);  

		;WITH wrapperCTE AS
		( 
			SELECT l.[itemId], l.[value], 
				   ROW_NUMBER() OVER (PARTITION BY l.[typeId], l.[itemId] ORDER BY l.[id] DESC) AS sorter
			  FROM [ForensicLogging].[Log] AS l
			 WHERE l.[typeId] = @logTypeId
		),existingCTE AS
		(
			SELECT cte.[itemId], cte.[value]
			  FROM wrapperCTE AS cte
			 WHERE cte.[sorter] = 1
		),currentCTE AS
		(
			SELECT l.id AS itemId, t.itemDetails AS value, das.id AS databaseServerId
			  FROM #tempOutput AS t
			 INNER JOIN [ForensicLogging].[LogItems] AS l 
			        ON l.theItemsId IS NULL AND 
					   l.name COLLATE DATABASE_DEFAULT = t.itemName COLLATE DATABASE_DEFAULT  
			 INNER JOIN [ForensicLogging].[databaseAndServer]  AS das
			        ON das.databaseName COLLATE DATABASE_DEFAULT = t.dbName COLLATE DATABASE_DEFAULT 
					AND das.serverName COLLATE DATABASE_DEFAULT = @@SERVERNAME COLLATE DATABASE_DEFAULT 
		)
		INSERT INTO [ForensicLogging].[Log] ([typeId], [itemId], [value], [databaseServerId]) 
		SELECT @logTypeId, c.*
		  FROM currentCTE AS c
		  LEFT JOIN existingCTE AS e ON e.[itemId] = c.[itemId] 
		      AND c.[value] COLLATE DATABASE_DEFAULT = e.[value] COLLATE DATABASE_DEFAULT 
		 WHERE e.[value] IS NULL;

		DROP TABLE #tempOutput;
	END	
END
GO
CREATE FUNCTION [ForensicLogging].[getSetting] ( @settingName NVARCHAR (50) )
RETURNS NVARCHAR(4000)
AS
BEGIN
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/OptionalSettings
	DECLARE @result AS NVARCHAR(4000);
	SET @result = '';

	SELECT @result = c.[value]
	  FROM [ForensicLogging].[Configuration] AS c
     WHERE c.[setting] = @settingName;

	RETURN @result;
END
GO
CREATE PROCEDURE [ForensicLogging].[setSetting]
	@setting NVARCHAR (50), 
	@value AS NVARCHAR(4000) OUTPUT
AS
BEGIN	
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/OptionalSettings
	MERGE [ForensicLogging].[Configuration]  AS target       
	USING (SELECT @setting AS settingName, @value AS settingValue) AS source (settingName, settingValue)       
	   ON (target.setting COLLATE DATABASE_DEFAULT = source.settingName COLLATE DATABASE_DEFAULT)   
	 WHEN NOT MATCHED THEN                                 
   INSERT ([setting], [value])                                 
   VALUES (source.settingName, source.settingValue);  

END
GO
CREATE PROCEDURE [ForensicLogging].[runFullMonitoringPass] 
AS
BEGIN
-- detailed documentation available at https://github.com/SteveStedman/SqlForensics/wiki/FunctionsAndProcedures
	SET NOCOUNT ON;
	DECLARE @displayChanges AS NVARCHAR(4000);
	DECLARE @previousMaxId AS BIGINT;
	
	SELECT 	@previousMaxId  = max(id) FROM [ForensicLogging].[Log];
	SET @displayChanges = [ForensicLogging].[getSetting] ('DisplayChanges');
		
	EXECUTE [ForensicLogging].[monitorConfig];
	EXECUTE [ForensicLogging].[monitorUsers];
	EXECUTE [ForensicLogging].[monitorObjects];

	IF(@displayChanges = 'True')
	BEGIN
		SELECT li.[name], cast(l.[whenRecorded] AS datetime), l.[value]
		  FROM [ForensicLogging].[Log] l
		 INNER JOIN [ForensicLogging].[LogItems]  li ON li.[id] = l.[itemId]
		 WHERE l.id > @previousMaxId
		 ORDER BY l.[whenRecorded] DESC;
	END
END
GO

--EXEC sp_configure 'show advanced options', '0';



-- To Use schedule the following line in a regular running job. Perhaps once every 5 minutes.
EXECUTE [ForensicLogging].[runFullMonitoringPass] ;


-- To see results run this query
--SELECT li.[name], cast(l.[whenRecorded] AS datetime), l.[value]
--  FROM [ForensicLogging].[Log] l
--  INNER JOIN [ForensicLogging].[LogItems]  li ON li.[id] = l.[itemId]
--  ORDER BY [whenRecorded] DESC;





--EXEC sp_configure 'show advanced options', '1';
-- WAITFOR DELAY '00:00:02';
--EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
--EXEC sp_configure 'show advanced options', '0';
-- WAITFOR DELAY '00:00:02';

-- Note the 'DisplayChanges' option of 'True' (string value) means that the runFullMonitoringPass sproc will display what has changed in that specific run.
--EXECUTE [ForensicLogging].[setSetting] 'DisplayChanges', 'True';
--EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
--EXEC sp_configure 'show advanced options', '1';



--GO
--EXECUTE [ForensicLogging].[runFullMonitoringPass] ;
--WAITFOR DELAY '00:00:02';
--GO 1000

