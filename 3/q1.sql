-- Q1

SET SEARCH_PATH TO wetworldschema, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    num_open INT,
    num_cave INT,
    num_deep INT
);

DROP VIEW IF EXISTS OpenWaterSites CASCADE;
DROP VIEW IF EXISTS CaveSites CASCADE;
DROP VIEW IF EXISTS DeepSites CASCADE;
DROP VIEW IF EXISTS SupervisedOpenWaterSites CASCADE;
DROP VIEW IF EXISTS SupervisedCaveSites CASCADE;
DROP VIEW IF EXISTS SupervisedDeepSites CASCADE;
DROP VIEW IF EXISTS NumOpenSites CASCADE;
DROP VIEW IF EXISTS NumCaveSites CASCADE;
DROP VIEW IF EXISTS NumDeepSites CASCADE;

-- Find sites with open water, cave, and 30m dives
CREATE VIEW OpenWaterSites AS
SELECT id
FROM DiveSites
WHERE has_open_water = TRUE;

CREATE VIEW CaveSites AS
SELECT id
FROM DiveSites
WHERE has_cave = TRUE;

CREATE VIEW DeepSites AS
SELECT id
FROM DiveSites
WHERE has_deep = TRUE;

-- Only get the open water sites that have monitors to supervise
CREATE VIEW SupervisedOpenWaterSites AS
SELECT OpenWaterSites.id
FROM OpenWaterSites JOIN MonitorPrivileges
ON OpenWaterSites.id = MonitorPrivileges.site_id
JOIN PriceTable
ON PriceTable.monitor_id = MonitorPrivileges.monitor_id
AND OpenWaterSites.id = PriceTable.site_id
WHERE PriceTable.diving_type = 'open'
GROUP BY OpenWaterSites.id;

-- Only get the cave sites that have monitors to supervise
CREATE VIEW SupervisedCaveSites AS
SELECT CaveSites.id
FROM CaveSites JOIN MonitorPrivileges
ON CaveSites.id = MonitorPrivileges.site_id
JOIN PriceTable
ON PriceTable.monitor_id = MonitorPrivileges.monitor_id
AND CaveSites.id = PriceTable.site_id
WHERE PriceTable.diving_type = 'cave'
GROUP BY CaveSites.id;

-- Only get the deep sites that have monitors to supervise
CREATE VIEW SupervisedDeepSites AS
SELECT DeepSites.id
FROM DeepSites JOIN MonitorPrivileges
ON DeepSites.id = MonitorPrivileges.site_id
JOIN PriceTable
ON PriceTable.monitor_id = MonitorPrivileges.monitor_id
AND DeepSites.id = PriceTable.site_id
WHERE PriceTable.diving_type = 'deep'
GROUP BY DeepSites.id;

-- Count the number of available and supervised sites
CREATE VIEW NumOpenSites AS
SELECT COUNT(id) AS num_open
FROM SupervisedOpenWaterSites;

CREATE VIEW NumCaveSites AS
SELECT COUNT(id) AS num_cave
FROM SupervisedCaveSites;

CREATE VIEW NumDeepSites AS
SELECT COUNT(id) AS num_deep
FROM SupervisedDeepSites;

-- Answer
INSERT INTO q1
SELECT *
FROM NumOpenSites, NumCaveSites, NumDeepSites;
