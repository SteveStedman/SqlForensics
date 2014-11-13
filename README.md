#SqlForensics

See the Wiki for more details. https://github.com/SteveStedman/SqlForensics/wiki

##Installing
### Step 1 - Installation 
Open the InstallSqlForensics.sql file, review it and run it.
What the install does:
 * Creates a database called [SqlForensics].
 * Creates several tables in that database to track what happens when.
 * Creates several stored procedures to track different items.
### Step 2 - Schedule the monitoring job
Schedule the stored procedure called [ForensicLogging].[runFullMonitoringPass] to run regularly (every 5 minutes is suggested).

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

##Who
Do you work for a public company. Chance are that due to regulatory changes and personal liabiality 
associated with cybercrime negligence your CEO in the next year or two will be requiring much higher levels
of accountability on the data forensics. Back to the question of "Do you know what has changed in the database?"

##Features
+ Tracking database configuration changes (ie sp_configure)
+ Tracking of the adding of users Users
+ Tracking the adding or modification of Stored Procedures
+ Tracking the adding or modification of Functions


##To Do
+ Tracking of who changed what and when
 + Tables
 + Triggers
 + Foreign Keys
 + Schemas
 + Logins
 + Permissions
 + Add/Remove a Database
 + Instance / Server configurations
+ Alerting
+ Investigation Tools
+ Transaction Log Viewer

##What this is not
SqlForensics is not intended to monitor data in tables. It does not track what data users accessed.

##Want to contribute
Contact Steve Stedman for more info.  http://SteveStedman.com

Basically here is how it works...

For this Repository, add a feature, test it make sure it is solid.  Submit a pull request to have the feature merged back into the main repo.  Note, not all changes will be accepted. 
