/* Q1: Who is the senior most employee based on job title? */

select title, last_name, first_name from employee
order by levels desc 
limit 1;


/* Q2: Which countries have the most Invoices? */

select billing_country, count(*) as invoices 
from invoice
group by billing_country 
order by invoices desc ;


/* Q3: What are top 3 values of total invoice? */

select total, billing_country
from invoice 
order by total desc
limit 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city, sum(total) as invoices_total
from invoice
group by billing_city
order by invoices_total desc
limit 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select c.customer_id, c.first_name  ,c.last_name, sum(i.total) as Total
from customer c
join invoice i 
on c.customer_id = i.customer_id 
group by c.customer_id
order by Total desc
limit 1;


/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

-- method 1
select distinct c.first_name, c.last_name, c.email, g.name
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line ii on i.invoice_id = ii.invoice_id
join track t on ii.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where g.name like 'Rock'
order by c.email;

-- method 2
SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select a.artist_id, a.name, count(t.track_id) as total
from track t
join album ab on t.album_id = ab.album_id
join artist a on a.artist_id = ab.artist_id
join genre g on t.genre_id = g.genre_id
where g.name like 'Rock'
group by a.artist_id
order by total desc
limit 10;


/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds
from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;


/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

with best_selling_artist as (
	select ar.artist_id, ar.name, sum(i.unit_price * i.quantity) as Total
	from invoice_line i
	join track t on t.track_id = i.track_id
	join album a on a.album_id = t.album_id
	join artist ar on ar.artist_id = a.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.name, SUM(il.unit_price*il.quantity)
from invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;


/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

-- Method 1:
with popular_genre as (
	select count(li.quantity), c.country, g.name, g.genre_id,
	row_number() over(partition by c.country order by count(li.quantity) desc) as row_no
	from invoice_line li 
	join invoice i on i.invoice_id = li.invoice_id
	join customer c on c.customer_id = i.customer_id
	join track t on t.track_id = li.track_id
	join genre g on g.genre_id = t.genre_id
	group by 2,3,4
	order by 2 asc, 1 desc
)
select * from popular_genre where row_no <= 1;

-- Method 2:
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

-- Method 1:
WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

-- Method 2:
WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1