-- drop existing views if they exist to avoid conflicts during update
drop view if exists gold.vw_dim_accounts;
drop view if exists gold.vw_dim_features;
drop view if exists gold.vw_dim_subscriptions;
drop view if exists gold.vw_dim_date;
drop view if exists gold.vw_fact_accounts;
drop view if exists gold.vw_fact_subscriptions;
drop view if exists gold.vw_fact_featureusage;
drop view if exists gold.vw_fact_supporttickets;
drop view if exists gold.vw_fact_churnevents;
go
--dimension tables or views
create view gold.vw_dim_accounts as
select 
    ac.account_id,
    ac.account_name,
    ac.industry,
    ac.country,
    cast(ac.signup_date as date) as signup_date,
    ac.refferral_source,
    ac.is_trial,
    ac.churn_flag as account_churn_flag,
    isnull(ch.reason_code, 'active customer') as churn_reason_code,
    isnull(ch.is_reactivation, 'false') as is_reactivation,
    su.plan_tier,
    su.seats,
    su.billing_frequency,
    su.auto_renew_flag
from silver.ravenstack_accounts ac
left join silver.ravenstack_churn_events ch on ac.account_id = ch.account_id
left join silver.ravenstack_subscriptions su on ac.account_id = su.account_id;
go
create view gold.vw_dim_features as
select distinct
    feature_name,
    isnull(is_beta_feature, 'false') as is_beta_feature
from silver.ravenstack_feature_usage;
go
create view gold.vw_dim_subscriptions as
select 
    subscription_id,
    account_id,
    plan_tier,
    seats,
    billing_frequency,
    auto_renew_flag,
    is_trial,
    upgrade_flag,
    downgrade_flag,
    churn_flag as subscription_churn_flag
from silver.ravenstack_subscriptions;
go
create view gold.vw_dim_date as
select 
    cast(date_column as date) as date_id,
    datename(day, date_column) as day,
    datename(month, date_column) as month,
    datepart(quarter, date_column) as quarter,
    year(date_column) as year,
    case when datename(weekday, date_column) in ('saturday', 'sunday') then 1 else 0 end as is_weekend
from (
    select distinct cast(submitted_at as date) as date_column from silver.ravenstack_support_tickets union
    select distinct cast(start_date as date) from silver.ravenstack_subscriptions union
    select distinct cast(usage_date as date) from silver.ravenstack_feature_usage union
    select distinct cast(churn_date as date) from silver.ravenstack_churn_events union
    select distinct cast(signup_date as date) from silver.ravenstack_accounts
) d;
go
--fact tables or views
create view gold.vw_fact_revenue as
select 
    subscription_id,
    account_id,
    cast(start_date as date) as start_date_id,
    cast(end_date as date) as end_date_id,
    isnull(mrr_amount, 0.00) as mrr_amount,
    isnull(arr_amount, 0.00) as arr_amount,
    is_trial,
    upgrade_flag,
    downgrade_flag,
    churn_flag
from silver.ravenstack_subscriptions;
go
create view gold.vw_fact_featureusage as
select 
    fu.usage_id,
    fu.subscription_id,
    su.account_id,
    cast(fu.usage_date as date) as usage_date_id,
    fu.feature_name,
    isnull(fu.usage_count, 0) as usage_count,
    isnull(fu.usage_duration_secs, 0) as usage_duration_secs,
    isnull(fu.error_count, 0) as error_count
from silver.ravenstack_feature_usage fu
left join silver.ravenstack_subscriptions su on fu.subscription_id = su.subscription_id;
go
create view gold.vw_fact_supporttickets as
select 
    ticket_id,
    account_id,
    cast(submitted_at as date) as ticket_submitted_date_id,
    cast(closed_at as date) as ticket_closed_date_id,
    isnull(resolution_time_hours, 0.0) as resolution_time_hours,
    isnull(first_response_time_minutes, 0) as first_response_time_minutes,
    isnull(satisfaction_score, 0) as satisfaction_score,
    isnull(priority_raven, 'unknown') as priority_raven,
    isnull(escalation_flag, 'false') as escalation_flag
from silver.ravenstack_support_tickets;
go
create view gold.vw_fact_churnevents as
select 
    churn_event_id,
    account_id,
    cast(churn_date as date) as churn_date_id,
    isnull(refund_amount_usd, 0.00) as refund_amount_usd,
    isnull(preceding_upgrade_flag, 'false') as preceding_upgrade_flag,
    isnull(preceding_downgrade_flag, 'false') as preceding_downgrade_flag,
    isnull(is_reactivation, 'false') as is_reactivation,
    isnull(feedback_text, 'no feedback') as feedback_text
from silver.ravenstack_churn_events;
go
