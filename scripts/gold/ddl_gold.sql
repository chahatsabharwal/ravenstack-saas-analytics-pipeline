CREATE VIEW gold.vw_Dim_Accounts AS
WITH support_agg AS (
    SELECT 
        account_id,
        COUNT(ticket_id) AS total_tickets_count,
        AVG(resolution_time_hours) AS avg_resolution_time_hours,
        AVG(satisfaction_score) AS avg_satisfaction_score,
       (SUM(CASE 
               WHEN escalation_flag IN ('True','1') THEN 1
               WHEN escalation_flag IN ('False','0') THEN 0
               ELSE 0
               END) * 100.0 / COUNT(ticket_id)
        ) AS escalation_rate
    FROM silver.ravenstack_support_tickets
    GROUP BY account_id
)
SELECT 
    ac.account_id,
    ac.account_name,
    ac.industry,
    ac.country,
    ac.signup_date,
    ac.refferral_source,
    ac.is_trial,
	ac.churn_flag,
  --ISNULL(ch.churn_date,CAST('4001-04-01' as date)) as churn_date,
    ISNULL(ch.reason_code, 'Active Customer') AS reason_code,
    ISNULL(ch.refund_amount_usd, 0.00) AS refund_amount_usd,
    ISNULL(ch.is_reactivation, 'False') AS is_reactivation,
	su.plan_tier,
	su.seats,
	su.billing_frequency,
	su.auto_renew_flag,
	isnull(sa.total_tickets_count,0) as total_tickets_count,
    isnull(sa.avg_resolution_time_hours,0) as avg_resolution_time_hours,
    isnull(sa.avg_satisfaction_score,0) as avg_satisfaction_score,
    sa.escalation_rate
  --sp.resolution_time_hours,
  --sp.satisfaction_score,
  --sp.priority_raven,
  --sp.first_response_time_minutes
FROM silver.ravenstack_accounts ac
LEFT JOIN silver.ravenstack_churn_events ch ON ac.account_id = ch.account_id
left join silver.ravenstack_subscriptions su on ac.account_id=su.account_id
left join support_agg sa ON ac.account_id = sa.account_id
-------------------------------------------------------------------------------------
go
CREATE VIEW gold.vw_Dim_Features AS
WITH usage_stats AS (
    SELECT 
        subscription_id,
        feature_name,
        COUNT(usage_id) AS total_usage_events,
        SUM(usage_count) AS total_invocations,
        SUM(usage_duration_secs) AS total_duration_secs,
        SUM(error_count) AS total_errors
    FROM silver.ravenstack_feature_usage
    GROUP BY subscription_id, feature_name
)
SELECT 
    us.feature_name,
    us.subscription_id,
    su.account_id,
    ISNULL(us.total_usage_events,0) AS total_usage_events,
    ISNULL(us.total_invocations,0) AS total_invocations,
    ISNULL(us.total_duration_secs,0) AS total_duration_secs,
    ISNULL(us.total_errors,0) AS total_errors,
    ISNULL(fu.is_beta_feature,'False') AS is_beta_feature,
    su.plan_tier,
    su.seats,
    su.billing_frequency,
    ac.industry,
    ac.country
FROM usage_stats us
LEFT JOIN silver.ravenstack_feature_usage fu 
       ON us.feature_name = fu.feature_name AND us.subscription_id = fu.subscription_id
LEFT JOIN silver.ravenstack_subscriptions su 
       ON us.subscription_id = su.subscription_id
LEFT JOIN silver.ravenstack_accounts ac 
       ON su.account_id = ac.account_id;
---------------------------------------------------------------------------------------------------
go
CREATE VIEW gold.vw_Dim_Subscriptions AS
WITH usage_agg AS (
    SELECT 
        subscription_id,
        COUNT(usage_id) AS total_usage_events,
        SUM(usage_count) AS total_feature_invocations,
        SUM(usage_duration_secs) AS total_usage_duration_secs,
        SUM(error_count) AS total_errors
    FROM silver.ravenstack_feature_usage
    GROUP BY subscription_id
),
support_agg AS (
    SELECT 
        su.subscription_id,
        COUNT(st.ticket_id) AS tickets_count,
        AVG(st.resolution_time_hours) AS avg_resolution_time_hours,
        AVG(st.satisfaction_score) AS avg_satisfaction_score
    FROM silver.ravenstack_subscriptions su
    LEFT JOIN silver.ravenstack_support_tickets st 
        ON su.account_id = st.account_id
    GROUP BY su.subscription_id
)
SELECT 
    su.subscription_id,
    su.account_id,
    su.plan_tier,
    su.seats,
    su.billing_frequency,
    su.auto_renew_flag,
    su.is_trial,
    su.upgrade_flag,
    su.downgrade_flag,
    su.churn_flag,
    ISNULL(su.mrr_amount,0) AS mrr_amount,
    ISNULL(su.arr_amount,0) AS arr_amount,
    ISNULL(ua.total_usage_events,0) AS total_usage_events,
    ISNULL(ua.total_feature_invocations,0) AS total_feature_invocations,
    ISNULL(ua.total_usage_duration_secs,0) AS total_usage_duration_secs,
    ISNULL(ua.total_errors,0) AS total_errors,
    ISNULL(sa.tickets_count,0) AS tickets_count,
    ISNULL(sa.avg_resolution_time_hours,0) AS avg_resolution_time_hours,
    ISNULL(sa.avg_satisfaction_score,0) AS avg_satisfaction_score
FROM silver.ravenstack_subscriptions su
LEFT JOIN usage_agg ua ON su.subscription_id = ua.subscription_id
LEFT JOIN support_agg sa ON su.subscription_id = sa.subscription_id;
-------------------------------------------------------------------------------------------------
go
CREATE VIEW gold.vw_Dim_SupportTickets AS
SELECT 
    st.ticket_id,
    st.account_id,
    st.submitted_at,
    st.closed_at,
    ISNULL(st.resolution_time_hours,0) AS resolution_time_hours,
    ISNULL(st.first_response_time_minutes,0) AS first_response_time_minutes,
    ISNULL(st.satisfaction_score,0) AS satisfaction_score,
    ISNULL(st.priority_raven,'Unknown') AS priority_raven,
    ISNULL(st.escalation_flag,'False') AS escalation_flag,
    ac.industry,
    ac.country,
    su.plan_tier,
    su.billing_frequency,
    su.auto_renew_flag
FROM silver.ravenstack_support_tickets st
LEFT JOIN silver.ravenstack_accounts ac 
       ON st.account_id = ac.account_id
LEFT JOIN silver.ravenstack_subscriptions su 
       ON st.account_id = su.account_id;
----------------------------------------------------------------------------------------------------------------
go
CREATE VIEW gold.vw_Dim_Date AS
SELECT 
    CAST(date_column AS DATE) AS date_id,
    DATENAME(DAY,date_column) AS day,
    DATENAME(MONTH,date_column) AS month,
    DATEPART(QUARTER,date_column) AS quarter,
    YEAR(date_column) AS year,
    CASE WHEN DATENAME(WEEKDAY,date_column) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS is_weekend
FROM (
    SELECT DISTINCT 
        CAST(submitted_at AS DATE) AS date_column FROM silver.ravenstack_support_tickets
    UNION
    SELECT DISTINCT CAST(start_date AS DATE) FROM silver.ravenstack_subscriptions
    UNION
    SELECT DISTINCT CAST(usage_date AS DATE) FROM silver.ravenstack_feature_usage
    UNION
    SELECT DISTINCT CAST(churn_date AS DATE) FROM silver.ravenstack_churn_events
    UNION
    SELECT DISTINCT CAST(signup_date AS DATE) FROM silver.ravenstack_accounts
) d;
