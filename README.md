SqlForensics
============

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

To Do:
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
 + Database configurations
 + Instance / Server configurations
+ Alerting
+ Investigation Tools
+ Transaction Log Viewer
