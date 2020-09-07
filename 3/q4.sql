-- Q4
SET SEARCH_PATH TO wetworldschema, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    site_id INT,
    site_name VARCHAR(50),
    highest REAL,
    lowest REAL,
    average REAL
);

DROP VIEW IF EXISTS NumDiversPerBooking CASCADE;
DROP VIEW IF EXISTS MonitorAndSiteCosts CASCADE;
DROP VIEW IF EXISTS TotalBookingCosts CASCADE;

-- Counting the number of divers per booking
CREATE VIEW NumDiversPerBooking AS
SELECT booking_id, COUNT(diver_id) AS num_divers
FROM DiverBookings
GROUP BY booking_id;

-- Find the monitor and site costs for bookings
CREATE VIEW MonitorAndSiteCosts AS
SELECT DiveSites.id AS site_id,
DiveSites.name as site_name,
Bookings.id AS booking_id,
DiveSites.site_price AS site_price,
PriceTable.price AS monitor_price
FROM (Bookings JOIN PriceTable
ON Bookings.monitor_id = PriceTable.monitor_id AND
Bookings.site_id = PriceTable.site_id AND
Bookings.diving_time = PriceTable.diving_time AND
Bookings.diving_type = PriceTable.diving_type)
JOIN DiveSites
ON Bookings.site_id = DiveSites.id;

-- Find the total cost per dive
-- Assume that monitor price only has to be paid once per dive
CREATE VIEW TotalBookingCosts AS
SELECT MonitorAndSiteCosts.site_id AS site_id,
MonitorAndSiteCosts.site_name AS site_name,
((NumDiversPerBooking.num_divers * MonitorAndSiteCosts.site_price)
 + MonitorAndSiteCosts.monitor_price) AS total_cost
FROM MonitorAndSiteCosts JOIN NumDiversPerBooking
ON MonitorAndSiteCosts.booking_id = NumDiversPerBooking.booking_id;

-- Find highest, lowest, and average fees per dive
INSERT INTO q4
SELECT site_id, site_name, 
MAX(total_cost) AS highest, 
MIN(total_cost) AS lowest, 
AVG(total_cost) AS average
FROM TotalBookingCosts
GROUP BY site_id, site_name;
