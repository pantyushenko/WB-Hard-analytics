-- Часть 1

-- Задание 1.1: Найти клиента с самым долгим временем ожидания между заказом и доставкой.

select 
    c.customer_id,
    c.name,
    o.order_id,
    o.order_date,
    o.shipment_date,
    extract(epoch from (o.shipment_date - o.order_date)) / 3600 as waiting_time_in_hours  -- Время ожидания в часах
from 
    customers c
join 
    orders o on c.customer_id = o.customer_id
where 
    o.shipment_date is not null  -- Учитываем только доставленные заказы
order by 
    (o.shipment_date - o.order_date) desc  -- Сортировка по убыванию времени ожидания
limit 1;  -- Ограничиваем результат одним клиентом

-- Задание 1.2: Найти клиентов с наибольшим количеством заказов и для каждого из них найти среднее время между заказом и доставкой, а также общую сумму всех их заказов. Вывести клиентов в порядке убывания общей суммы заказов.

with customer_order_stats as (
    select 
        o.customer_id,
        count(o.order_id) as total_orders,  -- Общее количество заказов
        avg(extract(epoch from (o.shipment_date - o.order_date)) / 3600) as avg_waiting_time_hours,  -- Среднее время ожидания (в часах)
        sum(o.order_ammount) as total_order_amount  -- Общая сумма всех заказов
    from 
        orders o
    where 
        o.shipment_date is not null  -- Только заказы с доставкой
    group by 
        o.customer_id
),
max_orders as (
    select 
        max(total_orders) as max_total_orders  -- Максимальное количество заказов среди всех клиентов
    from 
        customer_order_stats
)
select 
    c.customer_id,
    c.name,
    cos.total_orders,
    round(cos.avg_waiting_time_hours, 2) as avg_waiting_time_hours,  -- Округляем среднее время ожидания до двух знаков после запятой
    cos.total_order_amount
from 
    customer_order_stats cos
join 
    max_orders mo on cos.total_orders = mo.max_total_orders  -- Выбираем клиентов с максимальным количеством заказов
join 
    customers c on c.customer_id = cos.customer_id
order by 
    cos.total_order_amount desc;  -- Сортируем по общей сумме заказов в порядке убывания

-- Задание 1.3: Найти клиентов с заказами, доставленными с задержкой более чем на 5 дней, и клиентов с отменёнными заказами. Вывести имя, количество таких заказов и их общую сумму. Отсортировать по общей сумме заказов в порядке убывания.

with delayed_orders as (
    select 
        customer_id,
        count(order_id) as delayed_count,  -- Количество заказов с задержкой более 5 дней
        sum(order_ammount) as delayed_sum  -- Сумма заказов с задержкой
    from 
        orders
    where 
        order_status = 'Approved'  -- Только доставленные заказы
        and shipment_date > order_date + interval '5 days'  -- Задержка более 5 дней
    group by 
        customer_id
),
cancelled_orders as (
    select 
        customer_id,
        count(order_id) as cancelled_count,  -- Количество отменённых заказов
        sum(order_ammount) as cancelled_sum  -- Сумма отменённых заказов
    from 
        orders
    where 
        order_status = 'Cancel'  -- Статус "Отменён"
    group by 
        customer_id
)
select 
    c.customer_id,
    c.name,
    coalesce(d.delayed_count, 0) as delayed_count,  -- Количество задержек (или 0, если их нет)
    coalesce(ca.cancelled_count, 0) as cancelled_count,  -- Количество отмен (или 0, если их нет)
    coalesce(d.delayed_sum, 0) + coalesce(ca.cancelled_sum, 0) as total_order_sum  -- Общая сумма таких заказов
from 
    customers c
left join 
    delayed_orders d on c.customer_id = d.customer_id  -- Присоединяем данные о задержанных заказах
left join 
    cancelled_orders ca on c.customer_id = ca.customer_id  -- Присоединяем данные об отменённых заказах
where 
    coalesce(d.delayed_count, 0) > 0 or coalesce(ca.cancelled_count, 0) > 0  -- Только клиенты с задержками или отменами
order by 
    total_order_sum desc;  -- Сортировка по общей сумме заказов в порядке убывания

-- Часть 2

-- Задача: Вычислить общую сумму продаж для каждой категории продуктов, определить категорию с наибольшей общей суммой продаж, и для каждой категории определить продукт с максимальной суммой продаж.

with category_sales as (
    select 
        p.product_category,
        sum(o.order_ammount) as total_sales  -- Общая сумма продаж по категории
    from 
        orders_2 o
    join 
        products_2 p on o.product_id = p.product_id
    group by 
        p.product_category
),
category_max_sales as (
    select 
        p.product_category,
        p.product_name,
        sum(o.order_ammount) as total_product_sales  -- Общая сумма продаж по продукту
    from 
        orders_2 o
    join 
        products_2 p on o.product_id = p.product_id
    group by 
        p.product_category, 
        p.product_name
),
max_product_sales as (
    select 
        cms.product_category,
        cms.product_name,
        cms.total_product_sales
    from 
        category_max_sales cms
    where 
        cms.total_product_sales = (
            select 
                max(total_product_sales)
            from 
                category_max_sales subquery
            where 
                subquery.product_category = cms.product_category
        )  -- Выбираем продукт с максимальными продажами в категории
)
select 
    cs.product_category,
    cs.total_sales as category_total_sales,
    mp.product_name as top_product,
    mp.total_product_sales as top_product_sales
from 
    category_sales cs
left join 
    max_product_sales mp on cs.product_category = mp.product_category
order by 
    cs.total_sales desc;  -- Сортировка категорий по общей сумме продаж в порядке убывания
