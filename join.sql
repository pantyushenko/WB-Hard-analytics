

-- Часть 1

-- Задание по пользователям

-- Выбираем город, возрастную категорию и количество покупателей в каждой категории по городам
select 
    city,
    case
        when age between 0 and 20 then 'young'
        when age between 21 and 49 then 'adult'
        else 'old'
    end as age_category,
    count(*) as buyer_count
from 
    users
group by 
    city,
    age_category
order by 
    city,
    buyer_count desc;

-- Задание по продуктам 

-- Вывести все записи из таблицы products
select * from products;

-- Рассчитываем среднюю цену категорий товаров, где в названии присутствуют слова 'hair' или 'home'
select 
    category,
    round(avg(price::numeric), 2) as avg_price  -- Округляем среднюю цену до двух знаков после запятой
from 
    products
where 
    name ilike '%hair%' or name ilike '%home%'  -- Ищем товары, содержащие 'hair' или 'home' в названии
group by 
    category;

-- Часть 2

-- Задание по продавцам

-- Пункт 1: Определяем успешных ('rich') и неуспешных ('poor') продавцов
select 
    seller_id,
    count(distinct category) as total_categ,  -- Количество уникальных категорий товаров
    round(avg(rating), 2) as avg_rating,      -- Средний рейтинг категорий
    sum(revenue) as total_revenue,            -- Суммарная выручка
    case 
        when count(distinct category) > 1 and sum(revenue) > 50000 then 'rich'  -- Успешные продавцы
        when count(distinct category) > 1 then 'poor'                           -- Неуспешные продавцы
        else null
    end as seller_type                      -- Метка 'rich' или 'poor'
from 
    sellers
where 
    category != 'Bedding'                   -- Исключаем категорию 'Bedding' из расчетов
group by 
    seller_id
order by 
    seller_id;

-- Пункт 2: Для неуспешных продавцов считаем месяцы с даты регистрации и разницу в сроках доставки
with non_successful_sellers as (
    select 
        seller_id,
        min(date_reg) as date_reg,          -- Дата регистрации каждого продавца
        max(delivery_days) as max_delivery, -- Максимальный срок доставки
        min(delivery_days) as min_delivery  -- Минимальный срок доставки
    from 
        sellers
    where 
        category != 'Bedding'               -- Исключаем категорию 'Bedding' из расчетов
    group by 
        seller_id
    having 
        count(distinct category) > 1 and sum(revenue) <= 50000  -- Только неуспешные продавцы
)
select 
    seller_id,
    floor((current_date - date_reg) / 30) as month_from_registration,  -- Полные месяцы с даты регистрации
    (select 
         max(max_delivery) - min(min_delivery)  -- Разница между максимальным и минимальным сроками доставки среди неуспешных продавцов
     from 
         non_successful_sellers) as max_delivery_difference
from 
    non_successful_sellers
order by 
    seller_id;

-- Пункт 3: Отбор продавцов, зарегистрированных в 2022 году и продающих ровно 2 категории товаров
select
    seller_id,
    string_agg(category, ' - ' order by category) as category_pair  -- Собираем категории в строку с разделителем ' - ' в алфавитном порядке
from
    sellers
where
    extract(year from date_reg) = 2022         -- Только продавцы, зарегистрированные в 2022 году
group by
    seller_id
having
    count(distinct category) = 2               -- Ровно 2 уникальные категории
    and sum(revenue) > 75000;                  -- Суммарная выручка превышает 75 000
