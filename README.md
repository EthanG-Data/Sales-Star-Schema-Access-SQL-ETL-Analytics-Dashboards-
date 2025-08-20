# Sales-Star-Schema-Access-SQL-ETL-Analytics-Dashboards-
This project encapsulates the full lifecycle of building and analyzing a sales data mart:

1. **Entity-Relationship Diagram (ERD)**  
   - Visual schema of Fact and Dimension tables.  
   - Shows referential integrity and star schema design.  

2. **Access Database Build**  
   - Creation of tables (FactSales, Customer, Product, Salesperson, Salesorder).  
   - Relationships enforced in Access with a data file attached.  

3. **Portable SQL DDL Scripts**  
   - PostgreSQL schema files.  
   - Surrogate keys, constraints, and indexes defined.  

4. **ETL Pipeline**  
   - Python script to load CSV extracts into a relational database.  
   - Idempotent loading (safe to re-run).  

5. **Data Quality Checks**  
   - SQL scripts for referential integrity, duplicates, and negative/invalid values.  

6. **Analytics Queries**  
   - Revenue by customer, product, category, and salesperson.    
   - Cohort and retention analysis queries.  

7. **Business Intelligence Dashboard**  
   - Tableau file showcasing KPIs and visualizations.  
   - Screenshots included for quick preview.  

8. **Documentation**  
   - README with setup instructions and repo map.  
   - `data_dictionary.md` with field descriptions.  
   - `design_decisions.md` outlining schema rationale.  
