-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)

-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5


WITH RECURSIVE hops AS (
-- base case, airports reachable from YYZ on initial date
SELECT 1 AS n, outbound as prevOubound,
inbound AS prevInbound, s_arv AS prevArrival
FROM flight
WHERE outbound = 'YYZ' 
AND date(s_dep) = (SELECT day FROM day)

UNION ALL 

-- recursive case 
(SELECT n + 1 AS n, outbound as prevOutbound, 
inbound AS prevInbound, s_arv AS prevArrival
FROM flight INNER JOIN hops
ON hops.prevInbound = flight.outbound
-- check that the departure airport matches our previous arrival
WHERE --outbound = hops.prevInbound 
-- layover must be < 24 hours
(s_dep - hops.prevArrival) <= '24:00:00'
AND (s_dep - hops.prevArrival) >= '00:00:00'
-- next flight must be later date 
AND s_dep > hops.prevArrival
AND n < (SELECT n from n)))

SELECT prevInbound AS destination, n AS num_flights FROM hops;










