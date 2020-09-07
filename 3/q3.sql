-- Q3

SET SEARCH_PATH TO wetworldschema, public;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    identifier VARCHAR(20) NOT NULL,
    avg_cost REAL NOT NULL
);

DROP VIEW IF EXISTS DailyCapacities CASCADE;
DROP VIEW IF EXISTS NumDivers CASCADE;
DROP VIEW IF EXISTS MoreThanHalfSites CASCADE;
DROP VIEW IF EXISTS LessThanHalfSites CASCADE;
DROP VIEW IF EXISTS NumDiversPerBooking CASCADE;
DROP VIEW IF EXISTS MonitorAndSiteCosts CASCADE;
DROP VIEW IF EXISTS ExtraCosts CASCADE;
DROP VIEW IF EXISTS TotalBookingCosts CASCADE;
DROP VIEW IF EXISTS MoreThanHalfAvgCosts CASCADE; 
DROP VIEW IF EXISTS LessThanHalfAvgCosts CASCADE;

-- Assume that the total capacity is on a per-day basis
-- https://piazza.com/class/k41sgwxi3z31k8?cid=863

-- Find the total capacity for each site per day
CREATE VIEW DailyCapacities AS
SELECT id, 
2 * max_daytime + max_night AS
daily_capacity
FROM DiveSites;

-- Find the total number of divers for all days and sites where bookings exist
CREATE VIEW NumDivers AS
SELECT Bookings.diving_date AS diving_date,
Bookings.site_id AS site_id,
COUNT(DiverBookings.diver_id) + 1 AS num_divers
FROM Bookings JOIN DiverBookings
ON Bookings.id = DiverBookings.booking_id
GROUP BY Bookings.diving_date, Bookings.site_id;

-- Find sites that are more than half full on average
CREATE VIEW MoreThanHalfSites AS
SELECT NumDivers.site_id AS site_id
FROM NumDivers JOIN DailyCapacities
ON NumDivers.site_id = DailyCapacities.id 
GROUP BY NumDivers.site_id, DailyCapacities.daily_capacity
HAVING SUM(NumDivers.num_divers) / COUNT(NumDivers.diving_date)
> 0.5 * DailyCapacities.daily_capacity;

-- Find sites that are less than or equal to half full on average
CREATE VIEW LessThanHalfSites AS
SELECT NumDivers.site_id AS site_id
FROM NumDivers JOIN DailyCapacities
ON NumDivers.site_id = DailyCapacities.id 
GROUP BY NumDivers.site_id, DailyCapacities.daily_capacity
HAVING SUM(NumDivers.num_divers) / COUNT(NumDivers.diving_date)
<= 0.5 * DailyCapacities.daily_capacity;

-- Begin to compute average fees
-- Counting the number of divers per booking
CREATE VIEW NumDiversPerBooking AS
SELECT booking_id, COUNT(diver_id) AS num_divers
FROM DiverBookings 
GROUP BY booking_id;

-- Find the monitor and site costs
CREATE VIEW MonitorAndSiteCosts AS
SELECT DiveSites.id AS site_id,
DiveSites.name as site_name,
Bookings.id AS booking_id,
DiveSites.site_price AS site_price,
PriceTable.price AS monitor_price
FROM (Bookings JOIN PriceTable
ON Bookings.monitor_id = PriceTable.monitor_id AND
Bookings.diving_time = PriceTable.diving_time AND
Bookings.diving_type = PriceTable.diving_type)
JOIN DiveSites
ON Bookings.site_id = DiveSites.id;

-- Find the extra costs per booking
CREATE VIEW ExtraCosts AS
SELECT Bookings.id AS booking_id,
COALESCE(DiveSites.mask_price, 0) * 
CAST(Bookings.has_mask AS INT) +
COALESCE(DiveSites.regulator_price, 0) * 
CAST(Bookings.has_regulator AS INT) +
COALESCE(DiveSites.fins_price, 0) * 
CAST(Bookings.has_fins AS INT) +
COALESCE(DiveSites.wrist_computer_price, 0) *
CAST(Bookings.has_wrist_computer AS INT)
AS extra_cost
FROM Bookings JOIN DiveSites
ON Bookings.site_id = DiveSites.id;

-- Find the total cost per dive
-- Assume that monitor price only has to be paid once per dive
CREATE VIEW TotalBookingCosts AS
SELECT MonitorAndSiteCosts.site_id AS site_id,
MonitorAndSiteCosts.booking_id AS booking_id,
((NumDiversPerBooking.num_divers * MonitorAndSiteCosts.site_price)
+ MonitorAndSiteCosts.monitor_price) + ExtraCosts.extra_cost
AS total_cost
FROM (MonitorAndSiteCosts JOIN NumDiversPerBooking
ON MonitorAndSiteCosts.booking_id = NumDiversPerBooking.booking_id)
JOIN ExtraCosts 
ON MonitorAndSiteCosts.booking_id = ExtraCosts.booking_id;

-- Find avg costs for > half full sites
CREATE VIEW MoreThanHalfAvgCosts AS
SELECT AVG(TotalBookingCosts.total_cost) AS avg_cost
FROM TotalBookingCosts JOIN MoreThanHalfSites
ON TotalBookingCosts.site_id = MoreThanHalfSites.site_id;

-- Find avg costs for <= half full sites
CREATE VIEW LessThanHalfAvgCosts AS
SELECT AVG(TotalBookingCosts.total_cost) AS avg_cost
FROM TotalBookingCosts JOIN LessThanHalfSites
ON TotalBookingCosts.site_id = LessThanHalfSites.site_id;

-- Find average fees per dive, insert answer
INSERT INTO q3
(SELECT 'More Than Half' AS identifier, 
COALESCE(MoreThanHalfAvgCosts.avg_cost, 0) 
AS avg_cost FROM MoreThanHalfAvgCosts)
UNION
(SELECT 'Less Than Half', COALESCE(LessThanHalfAvgCosts.avg_cost, 0) 
FROM LessThanHalfAvgCosts);
