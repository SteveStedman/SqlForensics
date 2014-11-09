#SqlForensics

##Installing
Open the InstallSqlForensics.sql file, review it and run it.
What the install does:
 * Creates a database called [SqlForensics].
 * Creates several tables in that database to track what happens when.
 * Creates several stored procedures to track different items.

##What is it?
SQL Server logging system to help with forensics.

Why do you need this? Do you have databases that fall into any of the following categories:
 + HIPAA
 + DoD
 + PCI
 + SOX
 + Any Public Organization
 + Hold any personal information

The goal of this project is to give the DBA the ability to know what has been changed is the SQL Server 
database, and to keep that information around for an extended period. Imagine finding out that your company 
had been hacked 7 months ago and people had stolen credit cards. Is there a way that you can know for sure
that no modifications were made to your SQL Server during that hacking event.


##To Do
+ Tracking of who changed what and when
 + Stored Procedures
 + Functions
 + Tables
 + Triggers
 + Foreign Keys
 + Schemas
 + Users
 + Logins
 + Permissions
 + Add/Remove a Database
 + Instance / Server configurations
+ Alerting
+ Investigation Tools
+ Transaction Log Viewer

##Whats Done
+ Tracking database configuration changes (ie sp_configure)
 

##Want to contribute
Contact Steve Stedman for more info.

Basically here is how it works...

For this Repository, add a feature, test it make sure it is solid.  Submit a pull request to have the feature merged back into the main repo.  Note, not all changes will be accepted. 
