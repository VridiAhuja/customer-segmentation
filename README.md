# customer-segmentation
Customer Segmentation Using RFM Analysis with Power BI and SQL

This project demonstrates how to implement Customer Segmentation using the RFM (Recency, Frequency, Monetary) framework. The analysis focuses on identifying actionable insights from customer transaction data to support strategic business decisions, such as customer retention, loyalty programs, and revenue growth.

Project Overview:

Objective: To segment customers into actionable groups (e.g., Best Customers, At Risk) based on their purchase behavior and engagement.
Industry Context: Financial services or retail, focusing on improving customer retention, identifying high-value customers, and targeting marketing strategies.
Tools Used:
SQL: For data processing, RFM score calculations, and customer segmentation.
Power BI: For creating interactive dashboards and visualizations to explore and present insights.

Database Design:

Created three primary tables:
Customers: Stores customer demographics and attributes.
Transactions: Records transactional details such as date, amount, and customer ID.
RFM_calculations: Stores computed RFM metrics, scores, and customer segments.

RFM Analysis Workflow:

Recency: Time since the customer's last purchase.
Frequency: Number of transactions made by the customer.
Monetary: Total spending by the customer.
Customers were scored (1–5) for each metric and categorized into actionable segments (e.g., Best Customers, At Risk).


Actionable Insights:
Best Customers: High-frequency and high-monetary customers with recent activity. Recommended loyalty rewards to retain them.
At Risk: Customers with low engagement and spending. Recommended re-engagement campaigns.
Potential Customers: Moderate spenders with room to increase frequency. Recommended targeted upselling strategies.
