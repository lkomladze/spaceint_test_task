--Customers Table: Create a table named "customers" with columns for customer ID, customer
--name, email address, country, and any other relevant information.
CREATE TABLE customers (
    id               int generated always as identity primary key,
    customer_name    varchar(128) not null,
    email_address    varchar(128) unique not null,
    phone_number     varchar(32) unique not null,
    doc_number       varchar(16) not null,
    country          varchar(64) not null,
    created_at       timestamp default current_timestamp
);
create index idx_customers_coutry on customers (country);
--Products Table: Create a table named "products" with columns for product ID, product name,
--price, category, and any other relevant information.
CREATE TABLE products (
    id              int generated always as identity primary key,
    product_name    varchar(128) not null,
    price           decimal(16, 2) not null,
    category        varchar(64) not null,
    created_at      timestamp default current_timestamp
);
create index idx_products_prod_name on products (product_name);
create index idx_products_price     on products(price);
create index idx_products_category  on products(category);
--Sales Transactions Table: Create a table named "sales_transactions" with columns for transaction
--ID, customer ID (foreign key referencing the customers table), product ID (foreign key referencing
--the products table), purchase date, quantity purchased, and any other relevant information.
CREATE TABLE sales_transactions (
    id              int generated always as identity primary key,
    customer_id     int not null,
    product_id      int not null,
    purchase_date   date not null default current_date,
    quantity        int check (quantity > 0),
    foreign key (customer_id) references customers(id) on delete cascade,
    foreign key (product_id) references products(id) on delete cascade
);
create index idx_sales_transactions_purc_dt on sales_transactions(purchase_date);
create index idx_sales_transactions_prod_id on sales_transactions(product_id);
create index idx_sales_transactions_cust_id on sales_transactions(customer_id);
--Shipping Details Table: Create a table named "shipping_details" with columns for transaction ID
--(foreign key referencing the sales_transactions table), shipping date, shipping address, city,
--country, and any other relevant information.
CREATE TABLE shipping_details (
    transaction_id   int primary key,
    shipping_date    date,
    shipping_address varchar(256) not null,
    city             varchar(64) not null,
    country          varchar(64) not null,
    foreign key (transaction_id) references sales_transactions(id) on delete cascade
);
create index idx_shipping_details_ship_dt on shipping_details(shipping_date);
create index idx_shipping_details_city    on shipping_details(city);
create index idx_shipping_details_country on shipping_details(country);
--Ensure that tables are created in an optimized manner, utilizing data distribution and appropriate
--data types and constraints for each column. Establish proper relationships between the tables
--using foreign key constraints.
