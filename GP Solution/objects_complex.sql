--Customers Table: Create a table named "customers" with columns for customer ID, customer
--name, email address, country, and any other relevant information.
create table customers (
    id               uuid default uuid_generate_v4() primary key , --rig shemtxvevebshi gamosadegia magalitad roca sxva sourcedan datas imateb da riskia ID-ebi daimatchos
                                                                   --kide gasatvaliswinebelia rom tu uuid gamoikeneb riskis gamo, id Unique agar unda ikos
    customer_name    varchar(128) not null,
    email_address    varchar(128) unique not null,
    phone_number     varchar(32) unique not null,
    doc_number       varchar(16) not null,
    country          varchar(64) not null,
    created_at       timestamp default current_timestamp
);
create index idx_customers_coutry on customers (country); --ideashi reportingistvis am velze index gamosadegia
--#########################################################################################################################################################
--Products Table: Create a table named "products" with columns for product ID, product name,
--price, category, and any other relevant information.
create table products (
    id              uuid default uuid_generate_v4() primary key,  --aqac ID match riskis prevencia
    product_name    varchar(128) not null,
    price           decimal(16, 2) not null,
    category        varchar(64) not null,
    created_at      timestamp default current_timestamp
);
create index idx_products_prod_name on products (product_name);--es indexi ideurad gamosadegia product name-(eb)it ID-(ebi)s dasatrevad da shemdeg am ID-ebis shemdgom cxrilebshi sadzebnat
create index idx_products_price     on products(price);
create index idx_products_category  on products(category); -- sheidzleba composit index daedos category+price velebs situaciidan gamomdinare
--#########################################################################################################################################################
--Sales Transactions Table: Create a table named "sales_transactions" with columns for transaction
--ID, customer ID (foreign key referencing the customers table), product ID (foreign key referencing
--the products table), purchase date, quantity purchased, and any other relevant information.
create table sales_transactions (
    id              uuid default uuid_generate_v4(),
    customer_id     uuid not null,
    product_id      uuid not null,
    purchase_date   timestamp not null,
    quantity        int check (quantity > 0) not null,
    foreign key (customer_id) references customers(id) on delete cascade,
    foreign key (product_id) references products(id) on delete cascade
)partition by range(purchase_date);
--partitions
create table sales_transactions_2024_01 partition of sales_transactions for values from ('2024-01-01') to ('2024-02-01');--partition for 2024 january
--index partitions
create index idx_sales_transactions_2024_01_purchase_date ON sales_transactions_2024_01(purchase_date);
create index idx_sales_transactions_2024_01_customer_id ON sales_transactions_2024_01(customer_id);
create index idx_sales_transactions_2024_01_product_id ON sales_transactions_2024_01(product_id);
--am etapze mxolod 2024 wels vapartitioneb just davalebistvis,
--samomavlod rame sheduled procedure(an alternativa) sheidzleba gaketdes romelic periodulad daamatebs partitionebs msgavs stilshi:
do
$$
declare
    start_date     date := '2024-02-01';
    end_date       date;
    partition_name text;
begin
    for i in 0..10 loop
        --
        end_date := start_date + interval '1 month';
        partition_name := 'sales_transactions_' || to_char(start_date, 'yyyy_mm');
        --
        execute format(
                'create table if not exists %I partition of sales_transactions for values from (%L) to (%L);',
                partition_name, start_date, end_date
            );
        --
        execute format(
                'create index idx_%I_purchase_date on %I(purchase_date);',
                partition_name, partition_name
            );
        --
        execute format(
                'create index idx_%I_customer_id on %I(customer_id);',
                partition_name, partition_name
            );
        --
        execute format(
                'create index idx_%I_product_id on %I(product_id);',
                partition_name, partition_name
            );
        --
        start_date := end_date;
        --
    end loop;
end
$$;
--#########################################################################################################################################################
--Shipping Details Table: Create a table named "shipping_details" with columns for transaction ID
--(foreign key referencing the sales_transactions table), shipping date, shipping address, city,
--country, and any other relevant information.
create table shipping_details (
    transaction_id   uuid,
    shipping_date    timestamp,
    shipping_address varchar(256) not null,
    city             varchar(64) not null,
    country          varchar(64) not null
)partition by range(shipping_date);
--Davalebashi aq partition ar mchirdeba mara gamosadegia :d
--amis partitionebtan ertad indexirebis dawerac sheidzleba transaction_id,city da country-ze
--magram ar vcer radgan motxovnili ar aris da dzalian ar gadavtvirto, kods garchevac xo unda :D
--foreign key-s magivrad vwer function da triggers romelic insertamde gachekavs  am cxrilshi arsebuli transaction id modis tu ara sales_transactionidan (id veli)
--function
create or replace function check_transaction_exists()
returns trigger as
$$
begin
    if not exists (select 1 from sales_transactions where id = new.transaction_id) then
        raise exception 'Not Valid Transaction ID';
    end if;
    --
    if exists (select 1 from shipping_details where transaction_id = new.transaction_id) then
        raise exception 'Transaction ID Already Exists';
    end if;
    --
    return new;
end;
$$ language plpgsql;
--trigger
create trigger validate_transaction
before insert or update on shipping_details
for each row
execute function check_transaction_exists();
