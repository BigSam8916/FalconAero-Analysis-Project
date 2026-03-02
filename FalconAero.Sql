CREATE TABLE falcon (
	Flight_Number VARCHAR(50),
    Flight_Date DATE,
    Origin VARCHAR(10),
    Destination VARCHAR(10),
    Route VARCHAR(20),
    Aircraft_Type VARCHAR(50),
    Aircraft_Capacity INT,
    Passengers INT,
    Load_Factor NUMERIC(6,4),
    Flight_Hours NUMERIC(5,2),
    Season VARCHAR(20),
    Route_Category VARCHAR(20),
    Demand_Level VARCHAR(20),
    Ticket_Revenue NUMERIC(12,2),
    Ancillary_Revenue NUMERIC(12,2),
    Total_Revenue NUMERIC(12,2),
    Fuel_Cost NUMERIC(12,2),
    Maintenance_Cost NUMERIC(12,2),
    Crew_Cost NUMERIC(12,2),
    Depreciation_Cost NUMERIC(12,2),
    Insurance_Cost NUMERIC(12,2),
    Airport_Fees NUMERIC(12,2),
    Catering_Cost NUMERIC(12,2),
    Handling_Cost NUMERIC(12,2),
    Navigation_Fees NUMERIC(12,2),
    Sales_Distribution_Cost NUMERIC(12,2),
    Passenger_Service_Cost NUMERIC(12,2),
    Overhead_Cost NUMERIC(12,2),
    Marketing_Cost NUMERIC (12,2),
    IT_Systems_Cost NUMERIC(12,2),
    Total_Cost NUMERIC(12,2),
    Profit NUMERIC (12,2),
    Profit_Margin NUMERIC(6,2)
);

--import records--
--View table--
SELECT * FROM falcon;

--count number of rows--

SELECT
	COUNT (*) AS num_of_rows FROM falcon;

--Check for NULL--

SELECT
	COUNT(*) FILTER (WHERE route IS NULL) AS missing_route,
	COUNT(*) FILTER (WHERE total_revenue IS NULL) AS missing_revenue,
	COUNT(*) FILTER (WHERE total_cost IS NULL) AS missing_cost
FROM falcon;

--Add surrogate key to the table--

ALTER TABLE falcon
ADD COLUMN flight_id SERIAL PRIMARY KEY;

--Clean and Normalise the table by creating cost table--

CREATE TABLE falcon_cost AS
SELECT
    flight_id,
    cost_type,
    cost_amount
FROM falcon
CROSS JOIN LATERAL (
    VALUES
        ('Fuel', fuel_cost),
        ('Maintenance', maintenance_cost),
        ('Crew', crew_cost),
		('depreciation', depreciation_cost),
		('insurance', insurance_cost),
        ('Airport Fees', airport_fees),
		('catering', catering_cost),
		('handling', handling_cost),
		('navigation', navigation_fees),
		('sales distribution', sales_distribution_cost),
        ('Passenger Service', passenger_service_cost),
        ('Overhead', overhead_cost),
        ('Marketing', marketing_cost),
        ('IT Systems', it_systems_cost)
) AS c(cost_type, cost_amount);


SELECT * FROM falcon;
--see falcon_cost table--
SELECT * FROM falcon_cost;

--Join tables via flight_id--

--Aggregate functions--

SELECT
	SUM (total_revenue) AS total_revenue,
	SUM (profit)  AS total_profit,
	SUM (total_cost) AS total_cost,
	ROUND (SUM(profit)/ SUM(total_revenue),2) * 100 AS profit_margin,
	COUNT (flight_number) AS total_flight,
	ROUND (AVG (profit_margin),2) AS ave_profit_margin,
	COUNT (DISTINCT aircraft_type) AS aircraft_num,
	COUNT(route) AS total_route,
	SUM (aircraft_capacity) AS total_aircraft_capacity,
	SUM (passengers) AS total_passengers
FROM falcon;

--Find the diffrence in capacity and passenger loaded by aircrafts and routes--

SELECT
	aircraft_type,
	SUM(aircraft_capacity) AS total_capacity,
	SUM(passengers) AS total_passengers,
	SUM(aircraft_capacity)- SUM(passengers) AS empty_seats
FROM falcon
GROUP BY aircraft_type
ORDER BY empty_seats DESC;

--calculate ave revenue per flight, ave cost per flight, revenue per passenger, cost/passenger--

SELECT
	ROUND(AVG(total_revenue)/ COUNT(flight_number),2) AS ave_rev_flight,
   ROUND(AVG(total_cost)/ COUNT(flight_number),2) AS ave_cost_flight,
	ROUND(SUM(total_revenue)/ SUM(passengers),2) AS rev_per_pass,
	ROUND(SUM(total_cost)/ SUM(passengers),2) AS cost_per_pass
FROM falcon;

--Financial overview--
--Revenue vs Cost vs Profit by Quarter (Clustered Column)--

SELECT
	CONCAT('Q',EXTRACT(QUARTER FROM flight_date)) AS quarter,
	SUM(total_revenue) AS "Total revenue",
	SUM(total_cost) AS "Total cost",
	SUM(profit) AS "Total profit"
FROM falcon
GROUP BY quarter
ORDER BY quarter;

--Monthly revenue & profit trend--

SELECT
	EXTRACT(MONTH FROM flight_date) AS month,
	SUM(total_revenue) AS "Total revenue",
	SUM(profit) AS "Total profit"
FROM falcon
GROUP BY month
ORDER BY month;

--Profit by route top 10--
SELECT
	route,
	SUM(profit) AS "Total profit"
FROM falcon
GROUP BY route
ORDER BY "Total profit"  DESC
LIMIT 10;

--Route analysis--
--Revenue by origin--
SELECT 
	origin, 
	SUM(total_revenue) AS "total revenue"
FROM falcon
GROUP BY origin;

--revenue by destination--
SELECT 
	destination, 
	SUM(total_revenue) AS "total revenue"
FROM falcon
GROUP BY destination;

--profit contribution by route--
SELECT
	route,
	SUM(profit) AS total_profit,
	ROUND((SUM(profit) * 100.0)/SUM(profit) OVER(),2) AS "Profit%"
FROM falcon
GROUP BY route, profit
ORDER BY "Profit%" DESC;

--Revenue by aircraft type--
SELECT 
	aircraft_type,
	SUM(total_revenue) AS "total revenue"
FROM falcon
GROUP BY aircraft_type
ORDER BY "total revenue" DESC;

--Profit margin by aircraft type--

SELECT
	 aircraft_type,
	 SUM(profit) AS "total profit",
	 ROUND(SUM(profit)* 100.0 / SUM(SUM(profit)) OVER (),2) AS profit_margin
FROM falcon
GROUP BY aircraft_type
ORDER BY profit_margin DESC;

--Cost per flight per aircraft--

SELECT 
	aircraft_type,
	ROUND(SUM(total_cost)/COUNT(flight_number),2) AS cost_per_flight
FROM falcon
GROUP BY aircraft_type
ORDER BY cost_per_flight DESC;

--Revenue per passenger by route--
SELECT
	route,
	ROUND (SUM(total_revenue)/COUNT(passengers),2) AS revenue_pass
FROM falcon
GROUP BY route
ORDER BY revenue_pass DESC;

--cost per passenger by route--
SELECT
	route,
	ROUND (SUM(total_cost)/COUNT(passengers),2) AS cost_pass
FROM falcon
GROUP BY route
ORDER BY cost_pass DESC;

--profit margin by route--
SELECT
	 route,
	 SUM(profit) AS "total profit",
	 ROUND(SUM(profit)* 100.0 / SUM(SUM(profit)) OVER (),2) AS profit_margin
FROM falcon
GROUP BY route
ORDER BY profit_margin DESC;

--rank route by profitability--

select 
	route,
	SUM(profit) AS total_profit,
	RANK() OVER (ORDER BY SUM(profit) DESC) AS "profitability"
from falcon
group by route
order by profitability;

--identify top 20 profit routes--
WITH route_profit AS (
    SELECT
        route,
        SUM(profit) AS route_profit
    FROM falcon
    GROUP BY route
),
pareto AS (
    SELECT
        route,
        route_profit,
       ROUND(SUM(route_profit) OVER (
            ORDER BY route_profit DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0
        / SUM(route_profit) OVER (),2) AS cumulative_profit_pct
    FROM route_profit
)
SELECT *
FROM pareto
WHERE cumulative_profit_pct <= 20
ORDER BY route_profit DESC;
  
	
	
