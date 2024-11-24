-- Задание 1

-- В порядке возрастания зарплат (наибольшая зарплата)

-- Используем CTE для получения максимальной зарплаты в каждом отделе
with max_salaries as (
    select 
        industry,
        max(salary) as max_salary
    from 
        salary
    group by 
        industry
)
-- Выбираем сотрудников с максимальной зарплатой в их отделе
select 
    s.first_name,
    s.last_name,
    s.salary,
    s.industry
from 
    salary s
join 
    max_salaries ms on s.industry = ms.industry and s.salary = ms.max_salary
order by 
    s.industry;

-- Используем DISTINCT ON для получения сотрудников с наибольшей зарплатой без оконных функций
select distinct on (industry) 
    first_name,
    last_name,
    salary,
    industry
from 
    salary
order by 
    industry, salary desc, first_name;

-- Используем оконную функцию FIRST_VALUE для получения имени сотрудника с наибольшей зарплатой
select distinct on (industry)
    first_name,
    last_name,
    salary,
    industry
from (
    select 
        first_name,
        last_name,
        salary,
        industry,
        first_value(first_name || ' ' || last_name) over (
            partition by industry 
            order by salary desc, first_name
        ) as name_highest_sal
    from 
        salary
) subquery
order by industry, salary desc, first_name;

-- В порядке убывания зарплат (наименьшая зарплата)

-- Используем CTE для получения минимальной зарплаты в каждом отделе
with min_salaries as (
    select 
        industry,
        min(salary) as min_salary
    from 
        salary
    group by 
        industry
)
-- Выбираем сотрудников с минимальной зарплатой в их отделе
select 
    s.first_name,
    s.last_name,
    s.salary,
    s.industry
from 
    salary s
join 
    min_salaries ms on s.industry = ms.industry and s.salary = ms.min_salary
order by 
    s.industry;

-- Используем DISTINCT ON для получения сотрудников с наименьшей зарплатой без оконных функций
select distinct on (industry) 
    first_name,
    last_name,
    salary,
    industry
from 
    salary
order by 
    industry, salary, first_name;

-- Используем оконную функцию FIRST_VALUE для получения имени сотрудника с наименьшей зарплатой
select distinct on (industry)
    first_name,
    last_name,
    salary,
    industry
from (
    select 
        first_name,
        last_name,
        salary,
        industry,
        first_value(first_name || ' ' || last_name) over (
            partition by industry 
            order by salary, first_name
        ) as name_lowest_sal
    from 
        salary
) subquery
order by industry, salary, first_name;

-- Задание 2

---- 2.1 ---

-- Отбираем данные по продажам за 02.01.2016
-- Указываем для каждого магазина его адрес, сумму проданных товаров в штуках и рублях
select distinct
    s.shopnumber,
    sh.city,
    sh.address,
    sum(s.qty) over (partition by s.shopnumber) as sum_qty,              -- Сумма проданных товаров в штуках
    sum(s.qty * g.price) over (partition by s.shopnumber) as sum_qty_price -- Сумма проданных товаров в рублях
from 
    sales s
join 
    shops sh on s.shopnumber = sh.shopnumber
join 
    goods g on s.id_good = g.id_good
where 
    s.date = '2016-02-01'
order by 
    s.shopnumber;

---- 2.2 ---

-- Отбираем долю от суммарных продаж в рублях на дату, только по товарам направления "ЧИСТОТА"
select
    s.date as date_,
    sh.city,
    sum(s.qty * g.price) as sum_sales, -- Сумма продаж для города на дату
    round(sum(s.qty * g.price) / sum(sum(s.qty * g.price)) over (partition by s.date), 2) as sum_sales_rel
    -- Доля от общей суммы продаж на дату
from 
    sales s
join 
    shops sh on s.shopnumber = sh.shopnumber
join 
    goods g on s.id_good = g.id_good
where 
    g.category = 'ЧИСТОТА' -- Учитываем только товары категории "ЧИСТОТА"
group by 
    s.date, sh.city
order by 
    s.date, sh.city;

---- 2.3 ---

-- Выводим информацию о топ-3 товарах по продажам в штуках в каждом магазине в каждую дату
with ranked_sales as (
    select
        s.date as date_,
        s.shopnumber,
        s.id_good,
        rank() over (partition by s.date, s.shopnumber order by sum(s.qty) desc) as rank_
    from 
        sales s
    group by 
        s.date, s.shopnumber, s.id_good
)
select 
    date_,
    shopnumber,
    id_good
from 
    ranked_sales
where 
    rank_ <= 3
order by 
    date_, shopnumber;

---- 2.4 ---

-- Выводим для каждого магазина и товарного направления сумму продаж в рублях за предыдущую дату
-- Только для магазинов Санкт-Петербурга
with sales_with_details as (
    select
        s.date as date_,
        sh.shopnumber,
        g.category,
        sum(s.qty * g.price) as total_sales
    from 
        sales s
    join 
        shops sh on s.shopnumber = sh.shopnumber
    join 
        goods g on s.id_good = g.id_good
    where 
        sh.city = 'СПб' -- Только магазины Санкт-Петербурга
    group by 
        s.date, sh.shopnumber, g.category
),
sales_with_prev as (
    select
        date_,
        shopnumber,
        category,
        total_sales,
        lag(total_sales) over (partition by shopnumber, category order by date_) as prev_sales
    from 
        sales_with_details
)
select 
    date_,
    shopnumber,
    category,
    prev_sales
from 
    sales_with_prev
order by 
    date_, shopnumber, category; 

--- Задание 3 ---

-- Создаем таблицу для данных о поисковых запросах
create table query (
    searchid serial primary key,
    year int,
    month int,
    day int,
    userid int,
    ts bigint,
    devicetype varchar(50),
    deviceid int,
    query text
);

-- Вставляем примерные данные
insert into query (year, month, day, userid, ts, devicetype, deviceid, query)
values
(2024, 11, 21, 1, 1699968000, 'android', 101, 'к'),
(2024, 11, 21, 1, 1699968030, 'android', 101, 'ку'),
(2024, 11, 21, 1, 1699968060, 'android', 101, 'куп'),
(2024, 11, 21, 1, 1699968090, 'android', 101, 'купить'),
(2024, 11, 21, 1, 1699968150, 'android', 101, 'купить кур'),
(2024, 11, 21, 1, 1699968180, 'android', 101, 'купить куртку'),
(2024, 11, 21, 2, 1699968200, 'android', 102, 'к'),
(2024, 11, 21, 2, 1699968230, 'android', 102, 'ку'),
(2024, 11, 21, 2, 1699968290, 'android', 102, 'куп'),
(2024, 11, 21, 2, 1699968350, 'android', 102, 'купить'),
(2024, 11, 21, 2, 1699968410, 'android', 102, 'купить кур'),
(2024, 11, 21, 2, 1699968480, 'android', 102, 'купить куртку'),
(2024, 11, 21, 3, 1699968500, 'ios', 103, 'к'),
(2024, 11, 21, 3, 1699968600, 'ios', 103, 'ку'),
(2024, 11, 21, 3, 1699968650, 'ios', 103, 'куп'),
(2024, 11, 21, 3, 1699968700, 'ios', 103, 'купить'),
(2024, 11, 21, 3, 1699968800, 'ios', 103, 'купить кур'),
(2024, 11, 21, 3, 1699968900, 'ios', 103, 'купить куртку');

-- Проверяем вставленные данные
select * from query;

-- Определяем значение is_final для каждого запроса
with query_with_next as (
    select 
        q1.year,
        q1.month,
        q1.day,
        q1.userid,
        q1.ts,
        q1.devicetype,
        q1.deviceid,
        q1.query,
        lead(q1.query) over (partition by q1.userid, q1.deviceid order by q1.ts) as next_query,
        lead(q1.ts) over (partition by q1.userid, q1.deviceid order by q1.ts) as next_ts
    from query q1
    where q1.devicetype = 'android' -- Отбираем только запросы с устройства android
      and q1.year = 2024 -- Выбираем год 2024
      and q1.month = 11 -- Месяц ноябрь
      and q1.day = 21 -- День 21
)
select
    year,
    month,
    day,
    userid,
    ts,
    devicetype,
    deviceid,
    query,
    next_query,
    case
        when next_query is null then 1 -- Если после данного запроса больше ничего не искал
        when next_ts - ts > 180 then 1 -- Если до следующего запроса прошло более 3 минут
        when length(next_query) < length(query) and next_ts - ts > 60 then 2 -- Если следующий запрос был короче и прошло более 1 минуты
        else 0
    end as is_final
from query_with_next
where (case
        when next_query is null then 1
        when next_ts - ts > 180 then 1
        when length(next_query) < length(query) and next_ts - ts > 60 then 2
        else 0
    end) in (1, 2) -- Отбираем только запросы с is_final равным 1 или 2
order by ts;
