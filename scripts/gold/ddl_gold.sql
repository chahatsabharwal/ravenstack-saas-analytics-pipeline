--dimension tables or views
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
-------------------------------------------------------------------------------------------------
go
--fact tables or views
CREATE VIEW gold.vw_Fact_Accounts AS
WITH subscription_agg AS (
    SELECT 
        account_id,
        COUNT(subscription_id) AS total_subscriptions,
        SUM(ISNULL(mrr_amount,0)) AS total_mrr,
        SUM(ISNULL(arr_amount,0)) AS total_arr
    FROM silver.ravenstack_subscriptions
    GROUP BY account_id
),
feature_agg AS (
    SELECT 
        su.account_id,
        COUNT(fu.usage_id) AS total_usage_events,
        SUM(ISNULL(fu.usage_count,0)) AS total_invocations,
        SUM(ISNULL(fu.usage_duration_secs,0)) AS total_usage_duration_secs,
        SUM(ISNULL(fu.error_count,0)) AS total_errors
    FROM silver.ravenstack_feature_usage fu
    JOIN silver.ravenstack_subscriptions su 
        ON fu.subscription_id = su.subscription_id
    GROUP BY su.account_id
),
support_agg AS (
    SELECT 
        account_id,
        COUNT(ticket_id) AS tickets_count,
        AVG(ISNULL(resolution_time_hours,0)) AS avg_resolution_time_hours,
        AVG(ISNULL(satisfaction_score,0)) AS avg_satisfaction_score,
        SUM(CASE WHEN escalation_flag IN ('True','1') THEN 1 ELSE 0 END) AS escalations
    FROM silver.ravenstack_support_tickets
    GROUP BY account_id
),
churn_agg AS (
    SELECT 
        account_id,
        COUNT(churn_event_id) AS churn_events_count,
        MAX(ISNULL(churn_date, CAST('4001-01-01' AS DATE))) AS last_churn_date,
        MAX(ISNULL(reason_code,'Unknown')) AS last_churn_reason
    FROM silver.ravenstack_churn_events
    GROUP BY account_id
)
SELECT 
    ac.account_id,
    ac.account_name,
    ac.industry,
    ac.country,
    ac.signup_date,
    ac.refferral_source,
    ISNULL(sa.total_subscriptions,0) AS total_subscriptions,
    ISNULL(sa.total_mrr,0) AS total_mrr,
    ISNULL(sa.total_arr,0) AS total_arr,
    ISNULL(fa.total_usage_events,0) AS total_usage_events,
    ISNULL(fa.total_invocations,0) AS total_invocations,
    ISNULL(fa.total_usage_duration_secs,0) AS total_usage_duration_secs,
    ISNULL(fa.total_errors,0) AS total_errors,
    ISNULL(sp.tickets_count,0) AS tickets_count,
    ISNULL(sp.avg_resolution_time_hours,0) AS avg_resolution_time_hours,
    ISNULL(sp.avg_satisfaction_score,0) AS avg_satisfaction_score,
    ISNULL(sp.escalations,0) AS escalations,
    ISNULL(ch.churn_events_count,0) AS churn_events_count,
    ISNULL(ch.last_churn_date, CAST('4001-01-01' AS DATE)) AS last_churn_date,
    ISNULL(ch.last_churn_reason,'Unknown') AS last_churn_reason
FROM silver.ravenstack_accounts ac
LEFT JOIN subscription_agg sa ON ac.account_id = sa.account_id
LEFT JOIN feature_agg fa ON ac.account_id = fa.account_id
LEFT JOIN support_agg sp ON ac.account_id = sp.account_id
LEFT JOIN churn_agg ch ON ac.account_id = ch.account_id;
go
CREATE VIEW gold.vw_Fact_Subscriptions AS
SELECT 
    su.subscription_id,
    su.account_id,
    ISNULL(su.start_date, CAST('4001-01-01' AS DATE)) AS start_date,
    ISNULL(su.end_date, CAST('4001-01-01' AS DATE)) AS end_date,
    ISNULL(su.mrr_amount,0) AS mrr_amount,
    ISNULL(su.arr_amount,0) AS arr_amount,
    su.is_trial,
    su.upgrade_flag,
    su.downgrade_flag,
    su.churn_flag
FROM silver.ravenstack_subscriptions su;
go
CREATE VIEW gold.vw_Fact_FeatureUsage AS
SELECT 
    fu.usage_id,
    fu.subscription_id,
    fu.usage_date,
    fu.feature_name,
    ISNULL(fu.usage_count,0) AS usage_count,
    ISNULL(fu.usage_duration_secs,0) AS usage_duration_secs,
    ISNULL(fu.error_count,0) AS error_count,
    ISNULL(fu.is_beta_feature,'False') AS is_beta_feature
FROM silver.ravenstack_feature_usage fu;
go
CREATE VIEW gold.vw_Fact_SupportTickets AS
SELECT 
    st.ticket_id,
    st.account_id,
    ISNULL(st.submitted_at, CAST('4001-01-01' AS DATE)) AS submitted_at,
    ISNULL(st.closed_at, CAST('4001-01-01' AS DATE)) AS closed_at,
    ISNULL(st.resolution_time_hours,0) AS resolution_time_hours,
    ISNULL(st.first_response_time_minutes,0) AS first_response_time_minutes,
    ISNULL(st.satisfaction_score,0) AS satisfaction_score,
    ISNULL(st.priority_raven,'Unknown') AS priority_raven,
    ISNULL(st.escalation_flag,'False') AS escalation_flag
FROM silver.ravenstack_support_tickets st;
go
CREATE VIEW gold.vw_Fact_ChurnEvents AS
SELECT 
    ch.churn_event_id,
    ch.account_id,
    ISNULL(ch.churn_date, CAST('4001-01-01' AS DATE)) AS churn_date,
    ISNULL(ch.reason_code,'Unknown') AS reason_code,
    ISNULL(ch.refund_amount_usd,0.00) AS refund_amount_usd,
    ISNULL(ch.preceding_upgrade_flag,'False') AS preceding_upgrade_flag,
    ISNULL(ch.preceding_downgrade_flag,'False') AS preceding_downgrade_flag,
    ISNULL(ch.is_reactivation,'False') AS is_reactivation,
    ISNULL(ch.feedback_text,'No Feedback') AS feedback_text
FROM silver.ravenstack_churn_events ch;
