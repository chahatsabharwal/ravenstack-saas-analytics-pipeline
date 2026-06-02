/*
-----------------------------------------------------------
Bronze Tables Setup Script
-----------------------------------------------------------

What this does:
    - Creates tables inside the 'bronze' schema
    - If a table is already there, it will be dropped first
    - Use this script whenever you want to reset or rebuild
      the structure of the bronze tables
-----------------------------------------------------------
*/
if object_id ('bronze.ravenstack_accounts','U') is not null
	drop table bronze.ravenstack_accounts
create table bronze.ravenstack_accounts(
account_id nvarchar(50),
account_name nvarchar(50),
industry nvarchar(50),
country nvarchar(50),
signup_date date,
refferral_source nvarchar(50),
plan_tier nvarchar(50),
seats int,
is_trial nvarchar(50),
churn_flag nvarchar(50)
);
if object_id ('bronze.ravenstack_churn_events','U') is not null
	drop table bronze.ravenstack_churn_events
create table bronze.ravenstack_churn_events(
churn_event_id nvarchar(50),
account_id nvarchar(50),
churn_date date,
reason_code nvarchar(50),
refund_amount_usd float,
preceding_upgrade_flag nvarchar(50),
preceding_downgrade_flag nvarchar(50),
is_reactivation nvarchar(50),
feedback_text nvarchar(50)
);
if object_id ('bronze.ravenstack_feature_usage','U') is not null
	drop table bronze.ravenstack_feature_usage
	create table bronze.ravenstack_feature_usage(
usage_id nvarchar(50),
subscription_id nvarchar(50),
usage_date date,
feature_name nvarchar(50),
usage_count int,
usage_duration_secs int,
error_count	int,
is_beta_feature nvarchar(50)
);
if object_id ('bronze.ravenstack_subscriptions','U') is not null
	drop table bronze.ravenstack_subscriptions
create table bronze.ravenstack_subscriptions(
subscription_id nvarchar(50),
account_id nvarchar(50),
start_date date,
end_date date,
plan_tier nvarchar(50),
seats int,
mrr_amount int,
arr_amount int,
is_trial nvarchar(50),
upgrade_flag nvarchar(50),
downgrade_flag nvarchar(50),
churn_flag nvarchar(50),
billing_frequency nvarchar(50),
auto_renew_flag nvarchar(50)
);
if object_id ('bronze.ravenstack_support_tickets','U') is not null
	drop table bronze.ravenstack_support_tickets
create table bronze.ravenstack_support_tickets(
ticket_id nvarchar(50),
account_id nvarchar(50),
submitted_at date,
closed_at datetime,
resolution_time_hours nvarchar(50),
priority_raven nvarchar(50),
first_response_time_minutes nvarchar(50),
satisfaction_score nvarchar(50),
escalation_flag nvarchar(50)
);
