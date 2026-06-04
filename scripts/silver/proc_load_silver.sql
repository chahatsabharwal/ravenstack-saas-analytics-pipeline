/*
===============================================================
Stored Procedure: Load Silver Layer (Bronze → Silver)
===============================================================
Purpose:
    This procedure runs the ETL (Extract, Transform, Load) process.
    It moves data from the Bronze schema into the Silver schema
    after cleaning and transforming it.

Steps Performed:
    - Clear (truncate) all Silver tables.
    - Insert transformed and cleansed data from Bronze tables
      into the Silver tables.

Parameters:
    None.
    This procedure does not take any inputs or return any outputs.

How to Run:
    EXEC Silver.load_silver;
===============================================================
*/
create or alter procedure silver.load_silver as
begin
declare @start_time datetime,@end_time datetime,@batch_start_time datetime,@batch_end_time datetime
set @batch_start_time=getdate();
begin try
print '========================================================'
print '>>truncating table silver.ravenstack_accounts'
print '========================================================'
set @start_time=getdate();
truncate table silver.ravenstack_accounts
print '========================================================'
print 'inserting data into silver.ravenstack_accounts'
print '========================================================'
insert into ravenstack_dw.silver.ravenstack_accounts(
	account_id,
	account_name,
	industry,
	country,
	signup_date,
	refferral_source,
	plan_tier,
	seats,
	is_trial,
	churn_flag)
-- cleaning data for silver layer
-- ==========================================================================
select 
    isnull(account_id, -1) as account_id,
    isnull(trim(account_name), 'unknown account') as account_name,
    isnull(trim(industry), 'other') as industry,    
-- country full form mapping
case 
  when upper(trim(country)) = 'US' then 'usa'
  when upper(trim(country)) = 'AU' then 'australia'
  when upper(trim(country)) = 'CA' then 'canada'
  when upper(trim(country)) = 'DE' then 'germany'
  when upper(trim(country)) = 'FR' then 'france'
  when upper(trim(country)) = 'IN' then 'india'
  when upper(trim(country)) = 'UK' then 'united kingdom'
  else isnull(trim(country), 'N/A')
  end as country,
isnull(signup_date, cast('1900-01-01'as date)) as signup_date,
-- refferral source mapping
case 
  when lower(trim(refferral_source)) = 'partner' then 'partner'
  when lower(trim(refferral_source)) = 'ads' then 'ads'
  when lower(trim(refferral_source)) = 'event' then 'event'
  when lower(trim(refferral_source)) = 'organic' then 'organic'
  when lower(trim(refferral_source)) = 'other' then 'other'
  else isnull(trim(refferral_source), 'n/a')
  end as refferral_source,
case 
  when lower(trim(plan_tier)) = 'basic' then 'basic'
  when lower(trim(plan_tier)) = 'pro' then 'pro'
  when lower(trim(plan_tier)) = 'enterprise' then 'enterprise'
  else isnull(trim(plan_tier), 'n/a')
end as plan_tier,
    isnull(seats, 1) as seats,
    isnull(trim(is_trial), 'n') as is_trial,
    isnull(trim(churn_flag), 'n') as churn_flag
from ravenstack_dw.bronze.ravenstack_accounts;
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
-----------------------------------------------------
print '========================================================'
print '>>truncating table silver.ravenstack_churn_events'
print '========================================================'
set @start_time=getdate();
truncate table silver.ravenstack_churn_events
print '========================================================'
print 'inserting data into silver.ravenstack_churn_events'
print '========================================================'
insert into ravenstack_dw.silver.ravenstack_churn_events(
	churn_event_id,
	account_id,
	churn_date,
	reason_code,
	refund_amount_usd,
	preceding_upgrade_flag,
	preceding_downgrade_flag,
	is_reactivation,
	feedback_text)
--cleaning data for silver layer
--table name ravenstack_churn_events
--------------------------------------------------------------------------
select 
    isnull(churn_event_id, -1) as churn_event_id,
	isnull(account_id, -1) as account_id,    
isnull(churn_date, '1900-01-01') as churn_date,
-- reason_code mapping
case 
  when lower(trim(reason_code)) = 'budget' then 'budget'
  when lower(trim(reason_code)) = 'competitor' then 'competitor'
  when lower(trim(reason_code)) = 'features' then 'features'
  when lower(trim(reason_code)) = 'pricing' then 'pricing'
  when lower(trim(reason_code)) = 'support' then 'support'
  else isnull(trim(reason_code), 'unknown')
  end as reason_code,
    isnull(refund_amount_usd, 0) as refund_amount_usd,
    isnull(trim(preceding_upgrade_flag), 'n') as preceding_upgrade_flag,
    isnull(trim(preceding_downgrade_flag), 'n') as preceding_downgrade_flag,
	isnull(trim(is_reactivation), 'n') as is_reactivation,
	isnull(trim(feedback_text), 'unknown') as feedback_text
from ravenstack_dw.bronze.ravenstack_churn_events;
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
--------------------------------------------------------------------------------------
print '========================================================'
print '>>truncating table silver.ravenstack_feature_usages'
print '========================================================'
set @start_time=getdate();
truncate table silver.ravenstack_feature_usage
print '========================================================'
print 'inserting data into silver.ravenstack_feature_usage'
print '========================================================'
insert into ravenstack_dw.silver.ravenstack_feature_usage(
      usage_id,
      subscription_id,
      usage_date,
	  feature_name,
      usage_count,
      usage_duration_secs,
      error_count,
	  is_beta_feature)
-- cleaning data for silver layer
-- ==========================================================================
select 
    isnull(usage_id, -1) as usage_id,
	isnull(subscription_id, -1) as subscription_id,
    isnull(usage_date, '1900-01-01') as usage_date,
	isnull(trim(feature_name), 'unknown') as feature_name,
    isnull(usage_count, 0) as usage_count,
	isnull(usage_duration_secs, 0) as usage_duration_secs,
    isnull(error_count, 0) as error_count,
    isnull(trim(is_beta_feature), 'n') as is_beta_feature
from ravenstack_dw.bronze.ravenstack_feature_usage;
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
-------------------------------------------------------------------------------
print '========================================================'
print '>>truncating table silver.ravenstack_subscriptions'
print '========================================================'
set @start_time=getdate();
truncate table silver.ravenstack_subscriptions
print '========================================================'
print 'inserting data into silver.ravenstack_subscriptions'
print '========================================================'
insert into ravenstack_dw.silver.ravenstack_subscriptions(
	 subscription_id
      ,account_id
      ,start_date
      ,end_date
      ,plan_tier
      ,seats
      ,mrr_amount
      ,arr_amount
      ,is_trial
      ,upgrade_flag
      ,downgrade_flag
      ,churn_flag
      ,billing_frequency
      ,auto_renew_flag)
-- cleaning data for silver layer
--table name ravenstack_subscriptions
-- ==========================================================================
select 
    isnull(subscription_id, -1) as subscription_id,
	isnull(account_id, -1) as account_id,
	isnull(start_date, cast('1900-01-01' as date)) as start_date,
	isnull(end_date, cast('1900-01-01' as date)) as end_date,
-- referral source mapping
case 
  when lower(trim(plan_tier)) = 'basic' then 'basic'
  when lower(trim(plan_tier)) = 'pro' then 'pro'
  when lower(trim(plan_tier)) = 'enterprise' then 'enterprise'
  else isnull(trim(plan_tier), 'n/a')
end as plan_tier,
    isnull(seats, 1) as seats,
	isnull(mrr_amount, 0) as mrr_amount,
	isnull(arr_amount, 0) as arr_amount,
    isnull(trim(is_trial), 'n') as is_trial,
	isnull(trim(upgrade_flag), 'n') as upgrade_flag,
	isnull(trim(downgrade_flag), 'n') as downgrade_flag,
    isnull(trim(churn_flag), 'n') as churn_flag,
-- billing_frequency full form mapping
case 
  when lower(trim(billing_frequency)) = 'monthly' then 'monthly'
  when lower(trim(billing_frequency)) = 'yearly' then 'yearly'
  else isnull(trim(billing_frequency), 'unknown')
  end as billing_frequency,
    isnull(trim(auto_renew_flag), 'n') as auto_renew_flag
from ravenstack_dw.bronze.ravenstack_subscriptions;
set @end_time=getdate()
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
----------------------------------------------------------------------------------
print '========================================================'
print '>>truncating table silver.ravenstack_support_tickets'
print '========================================================'
set @start_time=getdate();
truncate table silver.ravenstack_support_tickets
print '========================================================'
print 'inserting data into silver.ravenstack_support_tickets'
print '========================================================'
insert into ravenstack_dw.silver.ravenstack_support_tickets (
       ticket_id
      ,account_id
      ,submitted_at
      ,closed_at
      ,resolution_time_hours
      ,priority_raven
      ,first_response_time_minutes
      ,satisfaction_score
      ,escalation_flag)
-- cleaning data for silver layer
-- ==========================================================================
-- table name ravenstack_support_tickets
-- check for unwanted spaces
select 
     isnull(ticket_id, -1) as ticket_id,
	 isnull(account_id, -1) as account_id,  
	 isnull(submitted_at, '1900-01-01') as submitted_at,
	 isnull(closed_at, '1900-01-01 00:00:00:000') as closed_at,
	 isnull(resolution_time_hours, 0.0) as resolution_time_hours,
-- priority_raven full form mapping
case 
  when lower(trim(priority_raven)) = 'low' then 'low'
  when lower(trim(priority_raven)) = 'medium' then 'medium'
  when lower(trim(priority_raven)) = 'high' then 'high'
  when lower(trim(priority_raven)) = 'urgent' then 'urgent'
  else isnull(trim(priority_raven), 'N/A')
  end as priority_raven,
    isnull(first_response_time_minutes, 0) as first_response_time_minutes,
	isnull(satisfaction_score, 0.0) as satisfaction_score,	
    isnull(trim(escalation_flag), 'n') as escalation_flag
from ravenstack_dw.bronze.ravenstack_support_tickets;
set @end_time=getdate();
print 'load duration' + cast(datediff(second,@start_time,@end_time) as nvarchar)
end try
------------------------------------------------------------------------------
begin catch
print '========================================';
print 'ERROR OCCURED DURING LOADING SILVER LAYER';
print 'error message' + ERROR_MESSAGE();
print 'error message' + cast(error_number() as nvarchar);
print 'error message' + cast(error_state() as nvarchar);
print '========================================';
end catch
set @batch_end_time=getdate()
print 'batch load duration' + cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar)
end;
