# ravenstack-saas-analytics-pipeline
An end-to-end data analytics pipeline for a B2B SaaS platform using medallion architecture (bronze,silver and gold layers) in sql to analyze and get metrics for customer retention and revenue optimization.

## Project Explanation
This project shows how I built a complete data pipeline using the RavenStack dataset.  
I followed the **Medallion Architecture** with three layers: Bronze, Silver, and Gold.  
The idea is simple: take raw data, clean it, and prepare it for analysis and dashboards.

### Bronze Layer
Raw data is loaded here. Nothing is changed, it’s just the starting point.

### Silver Layer
Data is cleaned and checked:
- Duplicates removed  
- Missing values handled  
- Correct data types applied  
- Relationships validated  

This makes the data reliable and ready for use.

### Gold Layer
Business‑ready views are created:
- **Fact views** have numbers and events (subscriptions, churn, usage, support tickets).  
- **Dimension views** have details (accounts, features, industries, dates).  

These are made as SQL views but act like fact and dimension tables.  
This layer is used for dashboards and reports.

## Dashboard and Insights
From the Gold layer, I can connect to BI tools like Power BI or Tableau.  
Some examples of insights:
- Revenue trends (MRR/ARR by plan tier)  
- Churn reasons and refund patterns  
- Feature usage and error counts  
- Support performance (resolution time, satisfaction, escalations)

## Purpose
This project is part of my portfolio. It shows:
- How I design and organize a data pipeline  
- How I clean and prepare data for analysis  
- How I build fact and dimension models in SQL  
- How I connect data to dashboards for business insights

## Credits

### Dataset
- **Source:** RavenStack: Synthetic SaaS Dataset (Multi-Table)  
- **Author:** River @ Rivalytics  
- **Platform:** Kaggle  
- **License:** MIT-like (synthetic, no PII)  
- **Note:** Dataset is used for educational and portfolio purposes with proper credit to the original author.

### Project
- **Design, modeling, and implementation:** Created by Chahat  
- **Scope:** Medallion architecture (Bronze → Silver → Gold), fact/dimension schema, quality checks, and dashboard development.  
- **Purpose:** Educational portfolio project demonstrating data engineering and BI skills.
