--1. Calculate the total sales amount and the total number of transactions for each month.
select date_trunc('MONTH', st.purchase_date) as month,
       sum(p.price * st.quantity)            as sales_amount,
       count(st.id)                          as transaction_count
from sales_transactions st
join products p on st.product_id = p.id
group by date_trunc('MONTH', st.purchase_date)
order by date_trunc('MONTH', st.purchase_date);

--2.Calculate the 3-month moving average of sales amount for each month. The moving
--  average should be calculated based on the sales data from the previous 3 months
--  (including the current month)
select dt.month,
       dt.sales_amount,
       avg(dt.sales_amount) over (order by dt.month rows between 2 preceding and current row)
from (select date_trunc('MONTH', st.purchase_date) as month,
             sum(p.price * st.quantity)            as sales_amount
      from sales_transactions st
      join products p on st.product_id = p.id
      group by date_trunc('MONTH', st.purchase_date)) dt;