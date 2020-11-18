/* UDACITY PROJECT */
/* Question Set 1 */
/* Question 1 */
/* We want to understand more about the movies that families are watching. The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music. */
SELECT f.title film_title, c.name category_name, COUNT(*) rental_count
  FROM category c
JOIN film_category fc
ON fc.category_id = c.category_id
JOIN film f
ON fc.film_id = f.film_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON r.inventory_id = i.inventory_id
WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
GROUP BY 1, 2
ORDER BY 2, 1;

/* Question 2 */
/* Now we need to know how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for. Can you provide a table with the movie titles and divide them into 4 levels (first_quarter, second_quarter, third_quarter, and final_quarter) based on the quartiles (25%, 50%, 75%) of the rental duration for movies across all categories? Make sure to also indicate the category that these family-friendly movies fall into. */
SELECT f.title film_name, c.name category_name, f.rental_duration,
	NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_quartile
  FROM category c
JOIN film_category fc
ON c.category_id = fc.category_id
JOIN film f
ON f.film_id = fc.film_id
WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music');

/* Question 3 */
/* Finally, provide a table with the family-friendly film category, each of the quartiles, and the corresponding count of movies within each combination of film category for each corresponding rental duration category.
The resulting table should have three columns:

Category
Rental length category
Count */
WITH t1 AS (SELECT f.title film_name, c.name category_name, f.rental_duration,
	NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_quartile
FROM category c
JOIN film_category fc
ON c.category_id = fc.category_id
JOIN film f
ON f.film_id = fc.film_id
WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))

SELECT category_name, standard_quartile, COUNT(*) num_films
FROM t1
GROUP BY 1, 2
ORDER BY 1, 2;

/* Question Set 2 */
/* Question 1 */
/* We want to find out how the two stores compare in their count of rental orders during every month for all the years we have data for. */
SELECT DATE_PART('month', r.rental_date) rental_month, DATE_PART('year', r.rental_date) rental_year,
s.store_id, COUNT(*) count_rentals
FROM store s
JOIN staff st
ON s.store_id = st.store_id
JOIN rental r
ON st.staff_id = r.staff_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC

/* Question 2 */
/* We would like to know who were our top 10 paying customers, how many payments they made on a monthly basis during 2007, and what was the amount of the monthly payments. Can you write a query to capture the customer name, month and year of payment, and total payment amount for each month by these top 10 paying customers? */
WITH amounts AS (SELECT c.customer_id, SUM(p.amount) total_amount
FROM customer c
JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY 1
ORDER BY total_amount DESC
LIMIT 10)

SELECT DATE_TRUNC('month', p.payment_date) pay_month, c.first_name || ' ' || c.last_name full_name,
       COUNT(p.amount)pay_countpermon, SUM(p.amount) pay_amounts
FROM amounts a
JOIN customer c
ON c.customer_id = a.customer_id
JOIN payment p
ON p.customer_id = c.customer_id
WHERE p.payment_date >= '2007-01-01' AND p.payment_date < '2008-01-01'
GROUP BY 1, 2
ORDER BY 2, 1

/* Question 3 */
/* Finally, for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007. Please go ahead and ** write a query to compare the payment amounts in each successive month.** Repeat this for each of these 10 paying customers. Also, it will be tremendously helpful if you can identify the customer name who paid the most difference in terms of payments. */
WITH t1 AS (SELECT c.customer_id, SUM(p.amount) total_amount
FROM customer c
JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY 1
ORDER BY total_amount DESC
LIMIT 10),

t2 AS (SELECT DATE_TRUNC('month', p.payment_date) pay_month, c.first_name || ' ' || c.last_name full_name,
       COUNT(p.amount)pay_countpermon, SUM(p.amount) pay_amounts
FROM t1
JOIN customer c
ON c.customer_id = t1.customer_id
JOIN payment p
ON p.customer_id = c.customer_id
WHERE p.payment_date >= '2007-01-01' AND p.payment_date < '2008-01-01'
GROUP BY 1, 2
ORDER BY 2, 1)

SELECT *,
      LAG(t2.pay_amounts) OVER (PARTITION BY full_name ORDER BY t2.pay_amounts) AS lag_amounts,
	  (pay_amounts - COALESCE(LAG(t2.pay_amounts) OVER (PARTITION BY full_name ORDER BY t2.pay_month), 0)) AS diff
FROM t2
	   ORDER BY diff DESC
