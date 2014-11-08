SET NOCOUNT ON;

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'SqlForensics')
BEGIN
	RAISERROR ('Database SqlForensics Already Exists', 20, 1)  WITH LOG
	/*
	ALTER DATABASE [SqlForensics] 
	  SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [SqlForensics];
	*/
END
CREATE DATABASE [SqlForensics];
GO

USE [SqlForensics];
GO
CREATE SCHEMA [ForensicLogging]; 


