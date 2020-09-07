-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS actualFlights CASCADE;

-- Define views for your intermediate steps here:
-- actual flights
CREATE VIEW actualFlights AS
SELECT * 
FROM Flight JOIN arrival ON Flight.id = arrival.flight_id;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1


-- Get passenger IDs including non-flying passengers

SELECT passenger.id as pass_id, firstname || ' ' || surname as name, count(DISTINCT airline) as airlines
FROM passenger LEFT JOIN booking ON passenger.id = booking.pass_id 
LEFT JOIN actualFlights ON actualFlights.flight_id = booking.flight_id
GROUP BY passenger.id;
