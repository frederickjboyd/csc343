-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS flights_departed CASCADE;
DROP VIEW IF EXISTS plane_capacities CASCADE;
DROP VIEW IF EXISTS flight_capacities CASCADE;
DROP VIEW IF EXISTS flight_count CASCADE;
DROP VIEW IF EXISTS flight_percentage CASCADE;
DROP VIEW IF EXISTS very_low CASCADE;
DROP VIEW IF EXISTS low CASCADE;
DROP VIEW IF EXISTS fair CASCADE;
DROP VIEW IF EXISTS normal CASCADE;
DROP VIEW IF EXISTS high CASCADE;
DROP VIEW IF EXISTS histogram CASCADE;

-- Define views for your intermediate steps here:

-- Get flight IDs of departed flights
CREATE VIEW flights_departed AS 
SELECT flight_id 
FROM Departure;

-- Get tail number and total capacity for all planes
CREATE VIEW plane_capacities AS 
SELECT tail_number, capacity_economy + capacity_business + capacity_first 
AS total_capacity
FROM Plane;

-- Get capacity for each flight
CREATE VIEW flight_capacities AS
SELECT Flight.id, total_capacity, tail_number 
FROM plane_capacities 
JOIN Flight 
ON plane_capacities.tail_number = Flight.plane;

-- Count how many people are on each flight
CREATE VIEW flight_count AS 
SELECT flight_id, count(*) AS num_people 
FROM Booking NATURAL JOIN flights_departed 
GROUP BY flight_id;

-- Get percentage that each flight is filled up
CREATE VIEW flight_percentage AS 
SELECT flight_id, CAST(num_people AS FLOAT) / total_capacity * 100 
AS percent_filled, tail_number 
FROM flight_capacities 
JOIN flight_count ON flight_capacities.id = flight_id;

-- Very low
CREATE VIEW very_low AS 
SELECT flight_id, count(*) AS very_low 
FROM flight_percentage 
WHERE percent_filled < 20 
GROUP BY flight_id;

-- Low
CREATE VIEW low AS 
SELECT flight_id, count(*) AS low 
FROM flight_percentage 
WHERE percent_filled >= 20 AND percent_filled < 40 
GROUP BY flight_id;

-- Fair
CREATE VIEW fair AS
SELECT flight_id, count(*) AS fair 
FROM flight_percentage 
WHERE percent_filled >= 40 AND percent_filled < 60
GROUP BY flight_id;

-- Normal
CREATE VIEW normal AS
SELECT flight_id, count(*) AS normal
FROM flight_percentage 
WHERE percent_filled >= 60 AND percent_filled < 80
GROUP BY flight_id;

-- High
CREATE VIEW high AS
SELECT flight_id, count(*) AS high
FROM flight_percentage 
WHERE percent_filled >= 80
GROUP BY flight_id;

-- Combine very low, low, fair, normal, and high to get plane histogram
CREATE VIEW histogram AS 
SELECT plane, count(very_low) AS very_low,
count(low) AS low,
count(fair) AS fair,
count(normal) AS normal,
count(high) AS high
FROM Flight LEFT JOIN 
(
	very_low NATURAL FULL JOIN 
	low NATURAL FULL JOIN 
	fair NATURAL FULL JOIN 
	normal NATURAL FULL JOIN
	high
)
ON Flight.id = flight_id
GROUP BY plane;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
SELECT airline, tail_number, very_low, low, fair, normal, high
FROM histogram 
JOIN Plane 
ON plane = tail_number;
