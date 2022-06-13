USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE; 

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];


--An exception occurred while enqueueing a message in the target queue. Error: 33009, State: 2. 
--The database owner SID recorded in the master database differs from the database owner SID recorded in database 'WideWorldImporters'. 
--You should correct this situation by resetting the owner of database 'WideWorldImporters' using the ALTER AUTHORIZATION statement.



  SELECT name, is_broker_enabled FROM sys.databases