DROP SCHEMA IF EXISTS wetworldschema CASCADE;
CREATE SCHEMA wetworldschema;
SET SEARCH_PATH to wetworldschema;

-- People who dive
CREATE TYPE certification AS ENUM ('NAUI', 'CMAS', 'PADI');
CREATE TABLE Divers (
  id INT PRIMARY KEY,
  -- First name
  firstname VARCHAR(50) NOT NULL,
  -- Last name
  lastname VARCHAR(50) NOT NULL,
  -- Birthday (can be <16 at time of booking but >=16 at time of dive)
  birthday DATE NOT NULL,
  -- Type of certification (assume unqualified divers not allowed to book)
  cert certification NOT NULL,
  -- Email
  email VARCHAR(30) NOT NULL
);

-- Dive monitors
CREATE TABLE Monitors (
  id INT PRIMARY KEY,
  -- First name
  firstname VARCHAR(50) NOT NULL,
  -- Last name
  lastname VARCHAR(50) NOT NULL,
  -- Email (technically not specified in data.txt but intuitively necessary to 
  -- contact monitors and notify them about bookings)
  email VARCHAR(30) NOT null,
  -- Maximum group size for each category of diving
  max_open_water INT NOT NULL,
  max_cave INT NOT NULL,
  max_deep INT NOT NULL
);

-- Diving sites
CREATE TABLE DiveSites (
  id INT PRIMARY KEY,
  -- Name of site
  name VARCHAR(50) NOT NULL,
  -- Name where site is located
  location VARCHAR(50) NOT NULL,
  -- Baseline site price independent of monitors
  site_price REAL NOT NULL,
  -- Maximum number of all divers during daylight hours (0 if N/A)
  max_daytime INT NOT NULL,
  -- Smaller maxima for night, cave, and >30m dives (0 if N/A)
  max_night INT NOT NULL,
  max_cave INT NOT NULL,
  max_deep INT NOT NULL,
  -- Whether dive site supports each category of diving
  has_open_water BOOLEAN NOT NULL,
  has_cave BOOLEAN NOT NULL,
  has_deep BOOLEAN NOT NULL,
  -- Services that dive sites may provide for additional fees
  -- We could use -1 to represent that a service is not available. 
  -- Although this would avoid the use of NULL values, it could be confusing 
  -- and using NULL values is a more intuitive solution.
  mask_price REAL,
  regulator_price REAL,
  fins_price REAL,
  wrist_computer_price REAL,
  -- Available free services
  has_videos BOOLEAN NOT NULL,
  has_snacks BOOLEAN NOT NULL,
  has_hot_showers BOOLEAN NOT NULL,
  has_towel_service BOOLEAN NOT NULL
);

-- Table of prices for monitors depending on site/type
CREATE TYPE diving_time AS ENUM ('morning', 'afternoon', 'night');
CREATE TYPE diving_type AS ENUM ('open', 'cave', 'deep');
CREATE TABLE PriceTable (
  -- Monitor
  monitor_id INT NOT NULL REFERENCES Monitors,
  -- Site that this entry corresponds to
  site_id INT NOT NULL REFERENCES DiveSites,
  -- Dive Time 
  diving_time diving_time NOT NULL,
  -- Dive Type  
  diving_type diving_type NOT NULL,
  -- Price (Assume Non Integer)
  price REAL NOT NULL,
  -- Attributes per price should be unique
  PRIMARY KEY(monitor_id, site_id, diving_time, diving_type)
);

-- List of diving sites that monitors have privileges at
-- This is different than PriceTable because monitors could book dives at sites 
-- where they do not have privileges
CREATE TABLE MonitorPrivileges (
  -- Monitor
  monitor_id INT NOT NULL REFERENCES Monitors,
  -- Site that they have privileges at
  site_id INT NOT NULL REFERENCES DiveSites,
  -- Ensure there are no duplicates
  PRIMARY KEY(monitor_id, site_id)
);

-- List of bookings made by lead divers
CREATE TABLE Bookings (
  id INT PRIMARY KEY,
  -- Lead diver who made booking
  lead_diver_id INT NOT NULL REFERENCES Divers,
  -- Monitor that will be supervising dive
  monitor_id INT NOT NULL REFERENCES Monitors,
  -- Time that booking was created
  booking_datetime TIMESTAMP NOT NULL,
  -- Date of dive
  diving_date DATE NOT NULL,
  -- Time of dive
  diving_time diving_time NOT NULL,
  -- Diving site that is booked
  site_id INT NOT NULL REFERENCES DiveSites,
  -- Category of diving
  diving_type diving_type NOT NULL,
  -- Credit card information for billing
  credit_card CHAR(16) NOT NULL,
    -- Has mask
  has_mask BOOLEAN NOT NULL,
  -- Has regulator
  has_regulator BOOLEAN NOT NULL,
  -- Has fins
  has_fins BOOLEAN NOT NULL,
  -- Has wrist computer
  has_wrist_computer BOOLEAN NOT NULL,
  -- Enforce constraint that lead diver cannot book more than one dive at a 
  -- given date and time
  UNIQUE(lead_diver_id, diving_date, diving_time),
  -- Check that a booking is not being made for a date in the past
  CHECK(diving_date >= DATE(booking_datetime))
);

-- All divers associated with a particular booking
-- Includes the lead diver
CREATE TABLE DiverBookings (
  -- Diver
  diver_id INT NOT NULL REFERENCES Divers,
  -- Booking that diver will be going to
  booking_id INT NOT NULL REFERENCES Bookings,
  -- Ensure there are no duplicates
  PRIMARY KEY(diver_id, booking_id)
);

-- Reviews for diving sites
CREATE TABLE DivingSiteReviews (
  id INT PRIMARY KEY,
  -- Diver giving review
  diver_id INT NOT NULL REFERENCES Divers,
  -- Site being reviewed
  site_id INT NOT NULL REFERENCES DiveSites,
  -- Rating from 0-5
  rating INT NOT NULL CHECK(rating >= 0 AND rating <= 5),
  -- Prevent divers from spamming reviews
  UNIQUE(diver_id, site_id)
);

-- Reviews of monitors by lead divers
CREATE TABLE MonitorReviews (
  id INT PRIMARY KEY,
  -- Lead diver giving the review
  lead_diver_id INT NOT NULL REFERENCES Divers,
  -- Booking id 
  booking_id INT NOT NULL REFERENCES Bookings,
  -- Review rating
  rating INT NOT NULL CHECK(rating >= 0 AND rating <= 5),
  -- One review per booking + diver
  UNIQUE(lead_diver_id, booking_id)
);

