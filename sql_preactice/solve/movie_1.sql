-- Active: 1745901812520@@127.0.0.1@5432@movie_rental@public

--2번 문제 동명이인의 영화배우가 있는가 없는가? 있으면 누가 동명이인인가? hint : group by 사용
-- 그룹바이는 지정한 컬럼에 대해서 그룹을 만들고 각 그룹별로 집계를 이룸 그러면 그 지정된 컬럼만 테이블에 존재하게 되는 것임
SELECT first_name, last_name,
       COUNT(*) AS actor_count
FROM actor
GROUP BY first_name, last_name
order BY actor_count DESC
;

-- 3번문제 국가별 회원수를 구하시오 hint : join, groupby
select country, count(*) as member_n
 from country 
inner join city using(country_id)
inner join address using(city_id)
inner join customer using(address_id)
GROUP BY country
ORDER BY member_n desc
;

-- 4번 rating 별 매출액을 구하시오 hint : join, groupby
select rating,sum(amount) from film
inner join inventory using(film_id)
inner join rental using(inventory_id)
inner join payment using(rental_id)
GROUP BY rating
order by rating DESC
;



-- 5번 4일이 지나면 연체가 된다고 가정하자. 전체 연 체율을 구하시오 hint : subquery, count
-- /(select count(*) from rental)
SELECT count(*)*1.0 / (select count(*) from rental) from rental where extract(DAY from age(return_date,rental_date))>= 4;

-- 6번 각 고객 별 평균 반납 기간 및 전체 반남기간 평 균을 계산하시오 hint : window, groupby, distinct
--  여기에 그룹 바이를 왜써야하는지 잘 모르겠다.
select DISTINCT customer_id, avg(age(return_date,rental_date))over(PARTITION BY customer_id ROWS BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING ) 
, (SELECT avg(age(return_date,rental_date)) as total_avg from rental)
from rental 
ORDER BY customer_id
;

select customer_id,avg(age(return_date,rental_date)), avg(avg(age(return_date,rental_date))) over(ROWS BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING ) from rental
GROUP BY customer_id
ORDER BY customer_id;
;

-- 7번 actor에 대한 문제임
-- actor_id, first_name, last_name, name
select *

from (select actor_id, first_name, last_name, name, count(*) as count_c, MAX(COUNT(*)) OVER (PARTITION BY actor_id) AS max_c
from actor
INNER JOIN film_actor using(actor_id)
INNER JOIN film_category using(film_id)
INNER JOIN category using(category_id)
GROUP BY actor_id, first_name, last_name, name
order by actor_id ) sub

where count_c = max_c
ORDER BY actor_id;


-- 8번
-- 월별비디오렌탈횟수가가장많은비디오들을 구해 오시오 hint : subquery, window function, groupby
-- title, extract(year from rental.rental_date), extract(month from rental.rental_date)
select *
from (select title, extract(year from rental.rental_date) as rental_year, extract(month from rental.rental_date) as rental_month, count(*)  as rental_count, max(count(*))  over(PARTITION BY rental_date) 
from film
inner join inventory using(film_id)
inner join rental using(inventory_id)
GROUP BY title, rental.rental_date) sub
where sub.max = sub.rental_count
order by sub.max DESC
;

-- 9 번 국가별 인기 영화를 구하시오 hint : subquery, window function, groupby, join

SELECT country, title, COUNT(*) AS rental_count, max(count(*)) over(PARTITION BY title)
from country 
inner join city using(country_id)
inner join address using(city_id)
inner join customer using(address_id)
inner join rental using(customer_id)
inner join inventory using(inventory_id)
inner join film using(film_id)
-- GROUP BY country, title
GROUP BY country, title
ORDER BY country, title ;

-- 10번 Replacement costs를 다음과 같이 그룹 지었을 때 각 그룹에 속하는 비디오의 개수를 구하시오 low: 9.99 - 19.99
-- medium: 20.00 - 24.99
-- high: 25.00 - 29.99 hint : CASE, groupby

select sub.cost_category, count(*) from (select *,
case   
    when replacement_cost >= 9.99 and replacement_cost  <= 19.99 then 'low'
    when replacement_cost >= 20.00 and replacement_cost  <= 24.99 then 'medium'
    when replacement_cost >= 25.00 and replacement_cost  <= 29.99 then 'high'
END AS cost_category
from film) sub
GROUP BY sub.cost_category
;


-- 11. 각 카테고리 별로 얼마나 많은 영화가 있는가 구하라 hint :groupby, join
select name, count(*) from film
inner join film_category using(film_id)
inner join category using(category_id)
group by name 

-- 12 주소 데이터 중 고객과 연관이 없는 주소 데이터만 구하여 그 개수가 몇 개인지 계산하시오 hint : join, filtering
-- left 조인 , left에 있을 애는 무조건 살리고 조합할 테이블은 겹치는게 있으면 붙인다.
select customer_id, count(*) from address
left join customer using(address_id)
GROUP BY customer_id
HAVING customer_id is NULL
;

-- 13 각 스탭 별로 고객 당 평균 이익(amount)를 올 렸는지 계산하시오. hint :subquery, window
select staff_id, avg(cus_sum) from (select staff_id, customer_id, sum(amount) as cus_sum from payment
GROUP BY staff_id,customer_id) sub
GROUP BY staff_id
;

-- 14 전체데이터중일요일평균매출액은? Hint :subquery, extract
select *, TRIM(TO_CHAR(payment_date, 'Day')) as Day, TO_CHAR(payment_date, 'yyyymmdd') from payment;


select avg(sub2.sum) from
(select sub.date, Day,sum(amount) 
from 
(select *, TRIM(TO_CHAR(payment_date, 'Day')) as Day, TO_CHAR(payment_date, 'yyyymmdd') as date from payment) 
sub
GROUP BY date, Day
HAVING Day = 'Sunday') sub2


-- 15 각 카테고리 별로 총매출액이 가장 높은 영화 를 찾으시오 Hint :subquery, window


SELECT 
  f.title,
  f.name AS category_name,
  sum(p.amount)
FROM (
  SELECT film_id, title, name
  FROM film
  JOIN film_category USING(film_id)
  JOIN category USING(category_id)
) f
JOIN (
  SELECT film_id, amount
  FROM payment
  JOIN rental USING(rental_id)
  JOIN inventory USING(inventory_id)
  JOIN film USING(film_id)
) p
using(film_id)
GROUP BY f.title, f.name
ORDER BY sum(p.amount) DESC




-- table 확인
select * from inventory;
select * from rental;
select * from payment ORDER BY customer_id;
select * from customer;
select * from actor;

select * from film_actor;
select * from film;
select * from category;
select * from film_category;

SELECT * from country;
select * from address;
select * from city;

select * from language;