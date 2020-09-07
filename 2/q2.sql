-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS all_refunds CASCADE;
DROP VIEW IF EXISTS completed_flights CASCADE;
DROP VIEW IF EXISTS domestic_flights CASCADE;
DROP VIEW IF EXISTS domestic_flights_long_delay CASCADE;
DROP VIEW IF EXISTS domestic_flights_short_delay CASCADE;
DROP VIEW IF EXISTS domestic_long_delay_refunds CASCADE;
DROP VIEW IF EXISTS domestic_short_delay_refunds CASCADE;
DROP VIEW IF EXISTS inbound_countries CASCADE;
DROP VIEW IF EXISTS international_flights CASCADE;
DROP VIEW IF EXISTS international_flights_long_delay CASCADE;
DROP VIEW IF EXISTS international_flights_short_delay CASCADE;
DROP VIEW IF EXISTS international_long_delay_refunds CASCADE;
DROP VIEW IF EXISTS international_short_delay_refunds CASCADE;
DROP VIEW IF EXISTS outbound_countries CASCADE;

-- Define views for your intermediate steps here:
-- Get flight IDs that have actually flown
-- Do not include flights that may be in progress
CREATE VIEW completed_flights AS
(SELECT flight_id
FROM Departure)
INTERSECT
(SELECT flight_id
FROM Arrival);

-- Get list of flight IDs and their outbound country
CREATE VIEW outbound_countries AS
SELECT id, country AS outbound_country
FROM Flight JOIN Airport
ON Flight.outbound = Airport.code
JOIN completed_flights
ON completed_flights.flight_id = Flight.id;
-- Get list of flight IDs and their inbound country
CREATE VIEW inbound_countries AS
SELECT id, country AS inbound_country
FROM Flight JOIN Airport
ON Flight.inbound = Airport.code;

-- Combine outbound_countries and inbound_countries to get domestic flights
-- Only include flights that are in completed_flights
CREATE VIEW domestic_flights AS
SELECT id
FROM outbound_countries NATURAL JOIN inbound_countries
WHERE outbound_countries.outbound_country = inbound_countries.inbound_country;
-- Ditto for international flights
CREATE VIEW international_flights AS
SELECT id
FROM outbound_countries NATURAL JOIN inbound_countries
WHERE outbound_countries.outbound_country != inbound_countries.inbound_country;

-- Domestic flight delays
-- Departure delay >= 4 hours but < 10 hours
CREATE VIEW domestic_flights_short_delay AS
SELECT id, s_dep, departure.datetime as departure_time,
s_arv, arrival.datetime as arrival_time
FROM domestic_flights JOIN departure
ON domestic_flights.id = departure.flight_id
JOIN arrival
ON domestic_flights.id = arrival.flight_id
NATURAL JOIN flight
WHERE (departure.datetime - s_dep) >= '4:00:00'
AND (departure.datetime - s_dep) < '10:00:00'
AND arrival.datetime - s_arv > 0.5 * (departure.datetime - s_dep);
-- Departure delay >= 10 hours
CREATE VIEW domestic_flights_long_delay AS
SELECT id, s_dep, departure.datetime as departure_time, 
s_arv, arrival.datetime as arrival_time
FROM domestic_flights JOIN departure
ON domestic_flights.id = departure.flight_id
JOIN arrival
ON domestic_flights.id = arrival.flight_id
NATURAL JOIN flight
WHERE (departure.datetime - s_dep) >= '10:00:00'
AND arrival.datetime - s_arv > 0.5 * (departure.datetime - s_dep);

-- International flight delays
-- Departure delay >= 7 hours but < 12 hours
CREATE VIEW international_flights_short_delay AS
SELECT id, s_dep, departure.datetime as departure_time, 
s_arv, arrival.datetime as arrival_time
FROM international_flights JOIN departure
ON international_flights.id = departure.flight_id
JOIN arrival
ON international_flights.id = arrival.flight_id
NATURAL JOIN flight
WHERE (departure.datetime - s_dep) >= '7:00:00'
AND (departure.datetime - s_dep) < '12:00:00'
AND arrival.datetime - s_arv > 0.5 * (departure.datetime - s_dep);
-- Departure delay >= 12 hours
CREATE VIEW international_flights_long_delay AS
SELECT id, s_dep, departure.datetime as departure_time, 
s_arv, arrival.datetime as arrival_time
FROM international_flights JOIN departure
ON international_flights.id = departure.flight_id
JOIN arrival
ON international_flights.id = arrival.flight_id
NATURAL JOIN flight
WHERE (departure.datetime - s_dep) >= '12:00:00'
AND arrival.datetime - s_arv > 0.5 * (departure.datetime - s_dep);

-- Calculate total refunds for each flight grouped by seat_class and year
-- Domestic flights with short delays
CREATE VIEW domestic_short_delay_refunds AS
SELECT booking.flight_id, seat_class, 0.35 * sum(price) as total,
extract(year FROM s_dep) as year
FROM booking JOIN domestic_flights_short_delay
ON booking.flight_id = domestic_flights_short_delay.id
GROUP BY seat_class, booking.flight_id, year;
-- Domestic flights with long delays
CREATE VIEW domestic_long_delay_refunds AS
SELECT booking.flight_id, seat_class, 0.5 * sum(price) as total,
extract(year FROM s_dep) as year
FROM booking JOIN domestic_flights_long_delay
ON booking.flight_id = domestic_flights_long_delay.id
GROUP BY seat_class, booking.flight_id, year;
-- International flights with short delays
CREATE VIEW international_short_delay_refunds AS
SELECT booking.flight_id, seat_class, 0.35 * sum(price) as total,
extract(year FROM s_dep) as year
FROM booking JOIN international_flights_short_delay
ON booking.flight_id = international_flights_short_delay.id
GROUP BY seat_class, booking.flight_id, year;
-- International flights with long delays
CREATE VIEW international_long_delay_refunds AS
SELECT booking.flight_id, seat_class, 0.5 * sum(price) as total,
extract(year FROM s_dep) as year
FROM booking JOIN international_flights_long_delay
ON booking.flight_id = international_flights_long_delay.id
GROUP BY seat_class, booking.flight_id, year;

-- Combine all refund tables
CREATE VIEW all_refunds AS
(SELECT * FROM domestic_short_delay_refunds)
UNION
(SELECT * FROM domestic_long_delay_refunds)
UNION
(SELECT * FROM international_short_delay_refunds)
UNION
(SELECT * FROM international_long_delay_refunds);

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
-- Now, group previous results by airline
SELECT airline, name, year, seat_class, sum(total) as refund
FROM all_refunds JOIN Flight
ON all_refunds.flight_id = Flight.id
JOIN Airline
ON Flight.airline = Airline.code
GROUP BY airline, name, year, seat_class, year
ORDER BY name;
