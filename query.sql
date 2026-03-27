create database UberAnalytics;
use UberAnalytics;

DESCRIBE uber_trips_dataset_50k;

SELECT * FROM uber_trips_dataset_50k LIMIT 10;


# there are few rows with 0KM and we can delete it from the DB

select * FROM uber_trips_dataset_50k
WHERE distance_km <= 0
   OR fare_amount <= 0;
   
DELETE FROM uber_trips_dataset_50k
WHERE distance_km <= 0
   OR fare_amount <= 0;

# changing format of both pickup_time and drop_time to datetime 
DESCRIBE uber_trips_dataset_50k;

-- alter table uber_trips_dataset_50k
-- modify pickup_time datetime;

-- alter table uber_trips_dataset_50k
-- modify drop_time datetime


-- How many total trips are in the dataset? #49997
select count(*) as total_trips 
from uber_trips_dataset_50k;


-- What is the date range of the trips? 
# '2023-01-01 00:00:00' - Min
# '2023-02-04 17:19:00' - Max


select min(pickup_time) as start_date,  max(pickup_time) as end_date
from uber_trips_dataset_50k;

-- Which cities are present?
select distinct city 
from uber_trips_dataset_50k;

-- What payment methods are used?
select distinct payment_method 
from uber_trips_dataset_50k;

-- What are the trip status types?
select distinct status 
from uber_trips_dataset_50k;

-- What is the min, max, and average fare?
select min(fare_amount) as minamount, 
max(fare_amount) as maxamount, 
avg(fare_amount) as avgamount
from uber_trips_dataset_50k;


-- What is the min, max, and average distance?
select min(distance_km) as mindistance, 
max(distance_km) as maxdistance, 
avg(distance_km) as avgdistance
from uber_trips_dataset_50k;


-- Are there any invalid rows (zero/negative fare or distance)?
select distance_km, fare_amount 
from uber_trips_dataset_50k
where distance_km <=0 or 
fare_amount <=0;

-- Are there any NULL values in key columns?
SELECT *
FROM uber_trips_dataset_50k
WHERE pickup_time IS NULL
   OR drop_time IS NULL
   OR city IS NULL
   OR fare_amount IS NULL
   OR distance_km IS NULL
   OR status IS NULL
   OR payment_method IS NULL;


-- How are trips distributed across cities?
select count(*), city 
from uber_trips_dataset_50k
group by city;

-- How many trips by daytime ?
SELECT DAYNAME(pickup_time) AS day,
COUNT(*) AS trips
FROM uber_trips_dataset_50k
GROUP BY day;

-- trips by hours
SELECT 
    HOUR(pickup_time) AS hour,
    COUNT(*) AS trips
FROM uber_trips_dataset_50k
GROUP BY hour
ORDER BY hour;

   
# phase 2 
# demand analysis

# what hour is the busiest?
select count(*) as trips, hour(pickup_time) as hour
from uber_trips_dataset_50k
group by hour
order by trips desc;


# which days of the week have the most trip?
-- SELECT 
--     DAYNAME(pickup_time) AS day,
--     COUNT(*) AS trips
-- FROM uber_trips_dataset_50k
-- GROUP BY day
-- ORDER BY FIELD(day, 'Monday','Tuesday','Wednesday',
-- 'Thursday','Friday','Saturday','Sunday');


select dayname(pickup_time) as day, count(*) as trips
from uber_trips_dataset_50k
group by day;
   
-- Revenue Analysis
-- Which city generates the most revenue?
select round(sum(fare_amount),2) as totalrevenue, city 
from uber_trips_dataset_50k
group by city;

-- What is the daily revenue trend?
SELECT 
    DATE(pickup_time) AS day,
    SUM(fare_amount) AS daily_revenue
FROM uber_trips_dataset_50k
GROUP BY day
ORDER BY day;

-- City Performance
-- Which city has:
-- Most trips
select count(*) as count, city 
from uber_trips_dataset_50k
group by city
order by count desc;

-- Highest average fare
select round(avg(fare_amount),2) avgamount, city
from uber_trips_dataset_50k
group by city
order by avgamount desc;

-- Longest trips
SELECT *
FROM uber_trips_dataset_50k
ORDER BY distance_km DESC
LIMIT 10;


-- Payment Behavior
-- Which payment method is used most?
select count(*) as noofpayment, payment_method
from uber_trips_dataset_50k
group by payment_method
order by noofpayment desc;

-- Does payment method affect fare or trip frequency?
SELECT 
    payment_method,
    AVG(fare_amount) AS avg_fare,
    MIN(fare_amount) AS min_fare,
    MAX(fare_amount) AS max_fare
FROM uber_trips_dataset_50k
GROUP BY payment_method
ORDER BY avg_fare DESC;

-- Trip Behavior
-- What is the average trip duration?
SELECT 
    AVG(TIMESTAMPDIFF(MINUTE, pickup_time, drop_time)) AS avg_duration_minutes
FROM uber_trips_dataset_50k;

-- Do longer trips always cost more?
select distance_km , fare_amount
from uber_trips_dataset_50k
order by distance_km desc
limit 20;


-- Operational Insights
-- What % of trips are cancelled vs completed?
SELECT 
    status,
    COUNT(*) AS total_trips,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM uber_trips_dataset_50k
GROUP BY status;


-- Which city has the highest cancellations?
SELECT 
    city,
    COUNT(*) AS cancelled_trips
FROM uber_trips_dataset_50k
WHERE status = 'cancelled'
GROUP BY city
ORDER BY cancelled_trips DESC;

-- How does cumulative revenue grow over time?

SELECT 
    DATE(pickup_time) AS day,
    SUM(fare_amount) AS daily_revenue,
    SUM(SUM(fare_amount)) OVER (ORDER BY DATE(pickup_time)) AS running_revenue
FROM uber_trips_dataset_50k
GROUP BY day;
   
-- At what hour is each city busiest?
SELECT *
FROM (
    SELECT 
        city,
        HOUR(pickup_time) AS hour,
        COUNT(*) AS trips,
        RANK() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS rnk
    FROM uber_trips_dataset_50k
    GROUP BY city, hour
) t
WHERE rnk = 1;

-- Which drivers complete the most trips?
SELECT 
    driver_id,
    COUNT(*) AS total_trips,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS driver_rank
FROM uber_trips_dataset_50k
GROUP BY driver_id;

-- Which drivers generate the most revenue?
SELECT 
    driver_id,
    SUM(fare_amount) AS revenue,
    RANK() OVER (ORDER BY SUM(fare_amount) DESC) AS rnk
FROM uber_trips_dataset_50k
GROUP BY driver_id;

-- Which trips are the longest in duration?
SELECT 
    trip_id,
    TIMESTAMPDIFF(MINUTE, pickup_time, drop_time) AS duration,
    RANK() OVER (ORDER BY TIMESTAMPDIFF(MINUTE, pickup_time, drop_time) DESC) as rnk
FROM uber_trips_dataset_50k;

-- What % of total revenue comes from each city?
SELECT 
    city,
    SUM(fare_amount) AS revenue,
    ROUND(SUM(fare_amount) * 100.0 / SUM(SUM(fare_amount)) OVER (), 2) AS percentage
FROM uber_trips_dataset_50k
GROUP BY city;

-- Which cities have the worst cancellation rates?
SELECT 
    city,
    COUNT(*) AS total_trips,
    SUM(status = 'cancelled') AS cancelled,
    ROUND(SUM(status = 'cancelled') * 100.0 / COUNT(*), 2) AS cancel_rate,
    RANK() OVER (ORDER BY SUM(status = 'cancelled') * 1.0 / COUNT(*) DESC) AS rnk
FROM uber_trips_dataset_50k
GROUP BY city;

-- Which hours are consistently busiest?
SELECT 
    HOUR(pickup_time) AS hour,
    COUNT(*) AS trips,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
FROM uber_trips_dataset_50k
GROUP BY hour;

-- What is the 3-day moving average of revenue?
SELECT 
    DATE(pickup_time) AS day,
    SUM(fare_amount) AS revenue,
    AVG(SUM(fare_amount)) OVER (
        ORDER BY DATE(pickup_time)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM uber_trips_dataset_50k
GROUP BY day;

-- Who are the top 3 drivers in each city?
SELECT *
FROM (
    SELECT 
        city,
        driver_id,
        COUNT(*) AS trips,
        RANK() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS rnk
    FROM uber_trips_dataset_50k
    GROUP BY city, driver_id
) t
WHERE rnk <= 3;

