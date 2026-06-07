-- finding duplicates and nulls in tables
-- table name ravenstack_accounts
-- expectations : no results
select account_id, count(*) 
from ravenstack_dw.silver.ravenstack_accounts
group by account_id
having count(*) > 1 or account_id is null;
-- found nothing
-- finding duplicates and nulls in tables
-- table name ravenstack_feature_usage
-- expectations : no results
select usage_id, count(*) 
from ravenstack_dw.silver.ravenstack_feature_usage
group by usage_id
having count(*) > 1 or usage_id is null;
-- found nothing
-- finding duplicates and nulls in tables
-- table name ravenstack_subscriptions
-- expectations : no results
select account_id, count(*) 
from ravenstack_dw.silver.ravenstack_subscriptions
group by account_id
having count(*) > 1 or account_id is null;
--check subscriptions which are inactive
select * from ravenstack_dw.silver.ravenstack_subscriptions
where start_date>end_date
-- found nothing
-- finding duplicates and nulls in tables
-- table name ravenstack_support_tickets
-- expectations : no results
select account_id, count(*) 
from ravenstack_dw.silver.ravenstack_support_tickets
group by account_id
having count(*) > 1 or account_id is null;
-- found nothing
select ticket_id, count(*)
from ravenstack_dw.silver.ravenstack_support_tickets
group by ticket_id
having count(*) > 1 or ticket_id is null;
-- found nothing
---------------------------------------------------------------------------------
--table ravenstack_churn_events_id
--churn_event_id repetition
select churn_event_id,count(*) from ravenstack_dw.silver.ravenstack_churn_events
group by churn_event_id
having count(*)>1 or churn_event_id is null
--account_id repetition
select account_id,count(*) from ravenstack_dw.silver.ravenstack_churn_events
group by account_id
having count(*)>1 or account_id is null
--output 175 rows
---------------------------------------------------------------------------------
select account_id,
       count(*) as duplicate_count
from ravenstack_dw.bronze.ravenstack_churn_events
where is_reactivation = 'false'
group by account_id
having count(*) > 1;
--output 149 rows
---------------------------------------------------------------------------------
