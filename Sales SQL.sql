CREATE TABLE customer (customer_key   INT NOT NULL AUTO_INCREMENT,
  customer_id    VARCHAR(64) UNIQUE,
  customer_name  VARCHAR(255) NOT NULL,
  address        VARCHAR(255),
  city           VARCHAR(128),
  state          VARCHAR(64),
  zipcode        VARCHAR(32),
  country        VARCHAR(64),
  PRIMARY KEY (customer_key)
);
CREATE TABLE salesperson (
  salesperson_key   INT NOT NULL AUTO_INCREMENT,
  salesperson_id    VARCHAR(64),
  salesperson_name  VARCHAR(255) NOT NULL,
  region            VARCHAR(128),
  CONSTRAINT pk_salesperson        PRIMARY KEY (salesperson_key),
  CONSTRAINT uq_salesperson_id     UNIQUE (salesperson_id)
) ;
CREATE TABLE product (
  product_key    INT NOT NULL AUTO_INCREMENT,
  product_id     VARCHAR(64),
  product_name   VARCHAR(255) NOT NULL,
  category       VARCHAR(128),
  price          DECIMAL(12,4),
  CONSTRAINT pk_product           PRIMARY KEY (product_key),
  CONSTRAINT uq_product_id        UNIQUE (product_id),
  CONSTRAINT chk_product_price    CHECK (price IS NULL OR price >= 0)
);
CREATE TABLE salesorder (
  salesorder_key   INT NOT NULL AUTO_INCREMENT,
  order_id         VARCHAR(64) NOT NULL,
  order_date       DATE NOT NULL,
  customer_key     INT NOT NULL,
  product_key      INT NOT NULL,
  quantity         DECIMAL(12,2) NOT NULL,
  salesperson_key  INT NULL,
  payment_type     VARCHAR(64),
  CONSTRAINT pk_salesorder PRIMARY KEY (salesorder_key),
  CONSTRAINT uq_salesorder_line UNIQUE (order_id, product_key, salesperson_key),
  CONSTRAINT fk_so_customer FOREIGN KEY (customer_key)
  REFERENCES customer(customer_key),
  CONSTRAINT fk_so_product      FOREIGN KEY (product_key)
  REFERENCES product(product_key),
  CONSTRAINT fk_so_salesperson  FOREIGN KEY (salesperson_key)
  REFERENCES salesperson(salesperson_key)
);
CREATE TABLE fact_sales (
  sales_key        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_key     INT NOT NULL,
  salesorder_key   INT NOT NULL,
  salesperson_key  INT NOT NULL,
  product_key      INT NOT NULL,
 CONSTRAINT pk_fact_sales        PRIMARY KEY (sales_key),
CONSTRAINT uq_fact_sales        UNIQUE (product_key, salesperson_key, salesorder_key),
 CONSTRAINT fk_f_customer     FOREIGN KEY (customer_key)    REFERENCES customer(customer_key),
  CONSTRAINT fk_f_salesorder   FOREIGN KEY (salesorder_key)  REFERENCES salesorder(salesorder_key),
  CONSTRAINT fk_f_salesperson  FOREIGN KEY (salesperson_key) REFERENCES salesperson(salesperson_key),
  CONSTRAINT fk_f_product      FOREIGN KEY (product_key)     REFERENCES product(product_key)
  );
  
  CREATE TABLE stg_salesperson (
  SalespersonID     VARCHAR(64),
  SalesPersonName   VARCHAR(255),
  Region            VARCHAR(128)
) ;
CREATE TABLE stg_salesorder (
  OrderID        VARCHAR(64),
  OrderDate      VARCHAR(32),
  CustomerID     VARCHAR(64),
  ProductID      VARCHAR(64),
  Quantity       VARCHAR(64),
  PaymentType    VARCHAR(64),
  SalesPersonID  VARCHAR(64)
);
CREATE TABLE stg_product (
  ProductID     VARCHAR(64),
  ProductName   VARCHAR(255),
  Category      VARCHAR(128),
  Price         VARCHAR(64) 
);
CREATE TABLE stg_customer (
  CustomerID     VARCHAR(64),
  Customername   VARCHAR(255),
  Address        VARCHAR(255),
  City           VARCHAR(128),
  State          VARCHAR(64),
  ZIPCode        VARCHAR(32),
  Country        VARCHAR(64)
);
SHOW VARIABLES LIKE 'local_infile'; 
SET GLOBAL local_infile=1;
USE sales;
LOAD DATA LOCAL INFILE 'C:/Users/adrie/OneDrive/Desktop/Sales_Salesperson.csv'
INTO TABLE stg_salesperson
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(SalespersonID, SalesPersonName, Region);

LOAD DATA LOCAL INFILE 'C:/Users/adrie/OneDrive/Desktop/Sales_Salesorder.csv'
INTO TABLE stg_salesorder
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(OrderID, OrderDate, CustomerID, ProductID, Quantity, PaymentType, SalesPersonID);

LOAD DATA LOCAL INFILE 'C:/Users/adrie/OneDrive/Desktop/Sales_product.csv'
INTO TABLE stg_product
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(ProductID, ProductName, Category, Price);

LOAD DATA LOCAL INFILE 'C:/Users/adrie/OneDrive/Desktop/Sales_customer.csv'
INTO TABLE stg_customer
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(CustomerID, Customername, Address, City, State, ZIPCode, Country);

INSERT INTO customer (customer_id, customer_name, address, city, state, zipcode, country)
SELECT DISTINCT s.CustomerID, s.Customername, s.Address, s.City, s.State, s.ZIPCode, s.Country
FROM stg_customer s
WHERE s.CustomerID IS NOT NULL
ON DUPLICATE KEY UPDATE
customer_name = VALUES(customer_name),
address = VALUES(address),
city = VALUES(city),
state = VALUES(state),
zipcode = VALUES(zipcode),
country = VALUES(country);

INSERT INTO product (product_id, product_name, category, price)
SELECT DISTINCT
  s.ProductID, s.ProductName, s.Category,
  CAST(NULLIF(REPLACE(REPLACE(s.Price,'$',''),',',''),'') AS DECIMAL(12,4))
FROM stg_product s
WHERE s.ProductID IS NOT NULL
ON DUPLICATE KEY UPDATE
product_name = VALUES(product_name),
category = VALUES(category),
price = VALUES(price);

INSERT INTO salesperson (salesperson_id, salesperson_name, region)
SELECT DISTINCT s.SalespersonID, s.SalesPersonName, s.Region
FROM stg_salesperson s
WHERE s.SalespersonID IS NOT NULL
ON DUPLICATE KEY UPDATE
  salesperson_name = VALUES(salesperson_name),
  region = VALUES(region);
  
INSERT INTO salesorder
  (order_id, order_date, customer_key, product_key, quantity, salesperson_key, payment_type)
SELECT
  so.OrderID,
  STR_TO_DATE(so.OrderDate, '%d-%b-%y') AS order_date,
  c.customer_key,
  p.product_key,
  CAST(NULLIF(so.Quantity,'') AS DECIMAL(12,2)),
  sp.salesperson_key,
  so.PaymentType
FROM stg_salesorder so
JOIN customer   c  ON c.customer_id   = so.CustomerID
JOIN product    p  ON p.product_id    = so.ProductID
LEFT JOIN salesperson sp ON sp.salesperson_id = so.SalesPersonID
ON DUPLICATE KEY UPDATE
order_date = VALUES(order_date),
customer_key = VALUES(customer_key),
product_key = VALUES(product_key),
quantity = VALUES(quantity),
salesperson_key = VALUES(salesperson_key),
payment_type = VALUES(payment_type);  

INSERT INTO fact_sales (customer_key, salesorder_key, salesperson_key, product_key)
SELECT so.customer_key, so.salesorder_key, so.salesperson_key, so.product_key
FROM salesorder so
LEFT JOIN fact_sales f
  ON f.salesorder_key = so.salesorder_key
 AND f.product_key    = so.product_key
 AND (f.salesperson_key <=> so.salesperson_key)  
WHERE f.sales_key IS NULL;

SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'product', COUNT(*) FROM product
UNION ALL SELECT 'salesperson', COUNT(*) FROM salesperson
UNION ALL SELECT 'salesorder', COUNT(*) FROM salesorder
UNION ALL SELECT 'fact_sales', COUNT(*) FROM fact_sales;

SELECT COUNT(*) AS missing_product
FROM salesorder so LEFT JOIN product p ON p.product_key=so.product_key
WHERE p.product_key IS NULL;