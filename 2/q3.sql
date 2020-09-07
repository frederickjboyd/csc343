-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS canadian_cities CASCADE;
DROP VIEW IF EXISTS american_cities CASCADE;
DROP VIEW IF EXISTS canadian_american_city_pairs CASCADE;
DROP VIEW IF EXISTS american_canadian_city_pairs CASCADE;
DROP VIEW IF EXISTS canada_america_direct CASCADE;
DROP VIEW IF EXISTS canada_america_direct_final CASCADE;
DROP VIEW IF EXISTS canada_america_one_connection CASCADE;
DROP VIEW IF EXISTS canada_america_one_connection_final CASCADE;
DROP VIEW IF EXISTS canada_america_two_connection CASCADE;
DROP VIEW IF EXISTS canada_america_two_connection_final CASCADE;
DROP VIEW IF EXISTS canada_to_america_flights CASCADE;
DROP VIEW IF EXISTS america_canada_direct CASCADE;
DROP VIEW IF EXISTS america_canada_direct_final CASCADE;
DROP VIEW IF EXISTS america_canada_one_connection CASCADE;
DROP VIEW IF EXISTS america_canada_one_connection_final CASCADE;
DROP VIEW IF EXISTS america_canada_two_connection CASCADE;
DROP VIEW IF EXISTS america_canada_two_connection_final CASCADE;
DROP VIEW IF EXISTS america_to_canada_flights CASCADE;

-- Define views for your intermediate steps here:

-- All Canadian cities
CREATE VIEW canadian_cities AS
SELECT city as canadian_city, code as canadian_city_code
FROM Airport
WHERE country = 'Canada';

-- All American cities
CREATE VIEW american_cities AS
SELECT city as american_city, code as american_city_code
FROM Airport
WHERE country = 'USA';

-- All American cities for each Canadian city
CREATE VIEW canadian_american_city_pairs AS
SELECT DISTINCT canadian_city, american_city
FROM canadian_cities, american_cities;

-- All Canadian cities for each American city
CREATE VIEW american_canadian_city_pairs AS
SELECT DISTINCT american_city, canadian_city
FROM american_cities, canadian_cities;

-- Direct flights from Canada to America
CREATE VIEW canada_america_direct AS
SELECT canadian_city, american_city, s_arv
FROM Flight
JOIN canadian_cities
ON outbound = canadian_city_code
JOIN american_cities
ON inbound = american_city_code
WHERE date(s_dep) = '2020-04-30'
AND date(s_arv) = '2020-04-30';

CREATE VIEW canada_america_direct_final AS
SELECT canadian_city, american_city, count(s_arv) AS direct, 
min(s_arv) as earliest_direct
FROM canada_america_direct 
NATURAL RIGHT JOIN canadian_american_city_pairs
GROUP BY canadian_city, american_city;

-- One connection flights from Canada to America
CREATE VIEW canada_america_one_connection AS
SELECT canadian_city, american_city, F2.s_arv
FROM Flight F1
JOIN Flight F2
ON F1.inbound = F2.outbound
JOIN canadian_cities
ON F1.outbound = canadian_city_code
JOIN american_cities
ON F2.inbound = american_city_code
WHERE date(F1.s_dep) = '2020-04-30'
AND date(F2.s_arv) = '2020-04-30'
AND F2.s_dep - F1.s_arv > '00:30:00';

CREATE VIEW canada_america_one_connection_final AS
SELECT canadian_city, american_city, count(s_arv) AS one_con,
min(s_arv) AS earliest_one_con
FROM canada_america_one_connection 
NATURAL RIGHT JOIN canadian_american_city_pairs
GROUP BY canadian_city, american_city;

-- Two connection flights from Canada to America
CREATE VIEW canada_america_two_connection AS
SELECT canadian_city, american_city, F3.s_arv
FROM Flight F1
JOIN Flight F2
ON F1.inbound = F2.outbound
JOIN Flight F3 
ON F2.inbound = F3.outbound
JOIN canadian_cities 
ON F1.outbound = canadian_city_code 
JOIN american_cities
ON F3.inbound = american_city_code
WHERE date(F1.s_dep) = '2020-04-30'
AND date(F3.s_arv) = '2020-04-30'
AND F2.s_dep - F1.s_arv > '00:30:00'
AND F3.s_dep - F2.s_arv > '00:30:00';

CREATE VIEW canada_america_two_connection_final AS
SELECT canadian_city, american_city, count(s_arv) AS two_con, 
min(s_arv) as earliest_two_con 
FROM canada_america_two_connection 
NATURAL RIGHT JOIN canadian_american_city_pairs
GROUP BY canadian_city, american_city;


-- Combine direct, single, and double connection flights
CREATE VIEW canada_to_america_flights AS 
SELECT canadian_city as outbound, american_city as inbound, 
direct, one_con, two_con, 
least(earliest_direct, earliest_one_con, earliest_two_con) AS earliest 
FROM canada_america_direct_final
NATURAL FULL JOIN canada_america_one_connection_final 
NATURAL FULL JOIN canada_america_two_connection_final;

-- Direct flights from America to Canada
CREATE VIEW america_canada_direct AS
SELECT american_city, canadian_city, s_arv
FROM Flight
JOIN american_cities
ON outbound = american_city_code 
JOIN canadian_cities 
ON inbound = canadian_city_code
WHERE date(s_dep) = '2020-04-30' 
AND date(s_arv) = '2020-04-30';

CREATE VIEW america_canada_direct_final AS 
SELECT american_city, canadian_city, count(s_arv) AS direct, 
min(s_arv) AS earliest_direct 
FROM america_canada_direct 
NATURAL RIGHT JOIN american_canadian_city_pairs 
GROUP BY american_city, canadian_city;

-- One connection from America to Canada
CREATE VIEW america_canada_one_connection AS 
SELECT american_city, canadian_city, F2.s_arv 
FROM Flight F1 
JOIN Flight F2 
ON F1.inbound = F2.outbound 
JOIN american_cities 
ON F1.outbound = american_city_code 
JOIN canadian_cities 
ON F2.inbound = canadian_city_code 
WHERE date(F1.s_dep) = '2020-04-30' 
AND date(F2.s_arv) = '2020-04-30' 
AND F2.s_dep - F1.s_arv > '00:30:00';

CREATE VIEW america_canada_one_connection_final AS 
SELECT american_city, canadian_city, count(s_arv) AS one_con, 
min(s_arv) AS earliest_one_con 
FROM america_canada_one_connection 
NATURAL RIGHT JOIN american_canadian_city_pairs 
GROUP BY american_city, canadian_city;

-- Two connections from America to Canada
CREATE VIEW america_canada_two_connection AS 
SELECT american_city, canadian_city, F3.s_arv 
FROM Flight F1 
JOIN Flight F2 
ON F1.inbound = F2.outbound 
JOIN Flight F3 
ON F2.inbound = F3.outbound 
JOIN american_cities 
ON F1.outbound = american_city_code 
JOIN canadian_cities 
ON F3.inbound = canadian_city_code 
WHERE date(F1.s_dep) = '2020-04-30' 
AND date(F3.s_arv) = '2020-04-30' 
AND F2.s_dep - F1.s_arv > '00:30:00' 
AND F3.s_dep - F2.s_arv > '00:30:00';

CREATE VIEW america_canada_two_connection_final AS 
SELECT american_city, canadian_city, count(s_arv) AS two_con, 
min(s_arv) AS earliest_two_con 
FROM america_canada_two_connection 
NATURAL RIGHT JOIN american_canadian_city_pairs 
GROUP BY american_city, canadian_city;

-- Combine direct, single, and double connection flights
CREATE VIEW america_to_canada_flights AS 
SELECT american_city AS outbound, canadian_city AS inbound, 
direct, one_con, two_con, 
least(earliest_direct, earliest_one_con, earliest_two_con) AS earliest 
FROM america_canada_direct_final 
NATURAL FULL JOIN america_canada_one_connection_final 
NATURAL FULL JOIN america_canada_two_connection_final;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3

-- Combine to get final answer
(SELECT * FROM canada_to_america_flights)
UNION
(SELECT * FROM america_to_canada_flights);

