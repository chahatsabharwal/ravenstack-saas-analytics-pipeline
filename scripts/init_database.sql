/*
============================================================
Database and Schema Setup
============================================================
Purpose:
    This script provisions a new database called 'ravenstack_dw'.
    - If 'ravenstack_dw' already exists, it will be dropped and recreated.
    - Within the database, three schemas are initialized:
        * bronze   → raw, unprocessed data
        * silver   → cleaned and standardized data
        * gold     → curated, business-ready data

Important Note:
    Running this script will permanently remove the existing 'ravenstack_dw' database
    along with all its contents. Ensure valid backups are in place before executing.
*/

use master;
go
--drop and recreate the 'ravenstack_dw' database
if exists (select 1 from sys.databases where name = 'ravenstack_dw')
begin
	alter database ravenstack_dw set single_user with rollback immediate;
	drop  database ravenstack_dw;
	end;
	go
--create database ravenstack_dw
create database ravenstack_dw;
go
use ravenstack_dw;
go
--create schemas
create schema bronze;
go
create schema silver;
go
create schema gold;
go
