-- Q2

SET SEARCH_PATH TO wetworldschema, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    monitor_id INT,
    avg_booking_fee REAL,
    email VARCHAR(30)
);

DROP VIEW IF EXISTS AvgMonitorRatings CASCADE;
DROP VIEW IF EXISTS HighestSiteRating CASCADE;
DROP VIEW IF EXISTS MonitorsHigherRatings CASCADE;
DROP VIEW IF EXISTS MonitorsHigherRatingsAvgPrice CASCADE;

-- Average ratings for each monitor
CREATE VIEW AvgMonitorRatings AS
SELECT Bookings.monitor_id, AVG(MonitorReviews.rating) AS avg_rating
FROM MonitorReviews JOIN Bookings
ON MonitorReviews.booking_id = Bookings.id
GROUP BY Bookings.monitor_id;

-- Highest site rating for each monitor
CREATE VIEW HighestSiteRating AS
SELECT PriceTable.monitor_id, MAX(DivingSiteReviews.rating) as max_rating
FROM DivingSiteReviews JOIN PriceTable
ON DivingSiteReviews.site_id = PriceTable.site_id
JOIN MonitorPrivileges
ON PriceTable.monitor_id = MonitorPrivileges.monitor_id
AND DivingSiteReviews.site_id = MonitorPrivileges.site_id
GROUP BY PriceTable.monitor_id;

-- Monitors with average rating higher than all dive sites they use
CREATE VIEW MonitorsHigherRatings AS
SELECT AvgMonitorRatings.monitor_id
FROM AvgMonitorRatings JOIN HighestSiteRating
ON AvgMonitorRatings.monitor_id = HighestSiteRating.monitor_id
AND AvgMonitorRatings.avg_rating > HighestSiteRating.max_rating;

-- Average booking fee for monitors that have average ratings higher than all 
-- dive sites they use
CREATE VIEW MonitorsHigherRatingsAvgPrice AS
SELECT MonitorsHigherRatings.monitor_id, AVG(PriceTable.price) AS avg_price
FROM MonitorsHigherRatings JOIN PriceTable
ON MonitorsHigherRatings.monitor_id = PriceTable.monitor_id
GROUP BY MonitorsHigherRatings.monitor_id;

-- Answer
INSERT INTO q2
SELECT Monitors.id AS monitor_id, 
MonitorsHigherRatingsAvgPrice.avg_price,
Monitors.email
FROM Monitors JOIN MonitorsHigherRatingsAvgPrice
ON Monitors.id = MonitorsHigherRatingsAvgPrice.monitor_id;
