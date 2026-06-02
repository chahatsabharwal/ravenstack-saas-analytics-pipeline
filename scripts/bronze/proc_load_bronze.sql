/*
---------------------------------------------------------------
Procedure: Load Bronze Layer (Source → Bronze)
---------------------------------------------------------------

What this does:
    - Clears (truncates) the bronze tables before loading
    - Loads fresh data from CSV files into bronze tables
      using BULK INSERT

Inputs/Outputs:
    - No parameters
    - Doesn’t return anything

How to run:
    EXEC bronze.load_bronze;
---------------------------------------------------------------
*/
create or alter procedure bronze.load_bronze as
begin
declare @start_time datetime,@end_time datetime,@batch_start_time datetime,@batch_end_time datetime
set @batch_start_time=getdate();
begin try
print '========================================'
print 'loading bronze layer'
print '========================================'
print '>>truncating bronze.ravenstack_accounts table'
truncate table bronze.ravenstack_accounts
print'>>inserting values in bronze.ravenstack_accounts'
set @start_time=getdate();
bulk insert bronze.ravenstack_accounts
from 'C:\temp\ravenstack_accounts.csv'
with(
firstrow=2,
fieldterminator=',',
tablock
);
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
print '>>truncating bronze.ravenstack_churn_events table'
truncate table bronze.ravenstack_churn_events
print'>>inserting values in bronze.ravenstack_churn_events'
set @start_time=getdate();
bulk insert bronze.ravenstack_churn_events
from 'C:\temp\ravenstack_churn_events.csv'
with(
firstrow=2,
fieldterminator=',',
tablock
);
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)

print '>>truncating bronze.ravenstack_feature_usage'
truncate table bronze.ravenstack_feature_usage
print'>>inserting values in bronze.ravenstack_feature_usage'
set @start_time=getdate();
bulk insert bronze.ravenstack_feature_usage
from 'C:\temp\ravenstack_feature_usage.csv'
with(
firstrow=2,
fieldterminator=',',
tablock
);
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
print '>>truncating bronze.ravenstack_subscriptions'
truncate table bronze.ravenstack_subscriptions
print'>>inserting values in bronze.ravenstack_subscriptions'
set @start_time=getdate();
bulk insert bronze.ravenstack_subscriptions
from 'C:\temp\ravenstack_subscriptions.csv'
with(
firstrow=2,
fieldterminator=',',
tablock
);
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
print '>>truncating bronze.ravenstack_support_tickets'
truncate table bronze.ravenstack_support_tickets
print'>>inserting values in bronze.ravenstack_support_tickets'
set @start_time=getdate();
bulk insert bronze.ravenstack_support_tickets
from 'C:\temp\ravenstack_support_tickets.csv'
with(
firstrow=2,
fieldterminator=',',
tablock
);
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
end try
begin catch
print '========================================';
print 'ERROR OCCURED DURING LOADING BRONZE LAYER';
print 'error message' + ERROR_MESSAGE();
print 'error message' + cast(error_number() as nvarchar);
print 'error message' + cast(error_state() as nvarchar);
print '========================================';
end catch
set @batch_end_time=getdate()
print 'batch load duration' + cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar)
end
