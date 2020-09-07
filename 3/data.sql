INSERT INTO Divers VALUES
(1, 'Michael', 'Smith', '1967-03-15', 'NAUI', 'michael@dm.org'),
(2, 'Dwight', 'Schrute', '1980-02-15', 'PADI', 'dwight@dm.org'),
(3, 'Jim', 'Halpert', '1970-08-05', 'CMAS', 'jim.halpert@dm.org'),
(4, 'Pam', 'Beesly', '1965-07-01', 'CMAS', 'pam@dm.org'),
(5, 'Andy', 'Bernard', '1973-10-10', 'PADI', 'andy@dm.org'),
(6, 'Phyllis', 'Blah', '1995-01-01', 'NAUI', 'phyllis@dm.org'),
(7, 'Oscar', 'Blah', '1995-01-01', 'NAUI', 'oscar@dm.org');

INSERT INTO Monitors VALUES
(1, 'Maria', 'Liu', 'maria@dm.org', 10, 5, 5),
(2, 'John', 'Doe', 'john.doe@dm.org', 15, 10, 10),
(3, 'Ben', 'Liang', 'ben@dm.org', 15, 5, 5);

INSERT INTO DiveSites VALUES
(1, 'Bloody Bay Marine Park', 'Little Cayman', 10.0, 10, 10, 10, 10, 
TRUE, TRUE, TRUE, 5.0, NULL, 10.0, NULL, FALSE, FALSE, FALSE, FALSE),
(2, 'Widow Makers Cave', 'Montego Bay', 20.0, 10, 10, 10, 10,
TRUE, TRUE, TRUE, 3.0, NULL, 5.0, NULL, FALSE, FALSE, FALSE, FALSE),
(3, 'Crystal Bay', 'Crystal Bay', 15.0, 10, 10, 10, 10,
TRUE, TRUE, TRUE, NULL, NULL, 5.0, 20.0, FALSE, FALSE, FALSE, FALSE),
(4, 'Batu Bolong', 'Batu Bolong', 15.0, 10, 10, 10, 10,
TRUE, TRUE, TRUE, 10.0, NULL, NULL, 30.0, FALSE, FALSE, FALSE, FALSE);

INSERT INTO PriceTable VALUES
(1, 1, 'night', 'cave', 25),
(1, 2, 'morning', 'open', 10),
(1, 2, 'morning', 'cave', 20),
(1, 3, 'afternoon', 'open', 15),
(1, 4, 'morning', 'cave', 30),
(2, 1, 'morning', 'cave', 15),
(3, 2, 'morning', 'cave', 20);

INSERT INTO MonitorPrivileges VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(2, 1),
(2, 3),
(3, 2);

INSERT INTO Bookings VALUES
(1, 1, 1, '2007-04-30 13:10:02', '2019-07-20', 'morning', 2, 'open', 
'1234567812345678', FALSE, FALSE, FALSE, FALSE),
(2, 1, 1, '2007-04-30 13:10:02', '2019-07-21', 'morning', 2, 'cave', 
'1234567812345678', FALSE, FALSE, FALSE, FALSE),
(3, 1, 2, '2007-04-30 13:10:02', '2019-07-22', 'morning', 1, 'cave', 
'0000111122223333', FALSE, FALSE, FALSE, FALSE),
(4, 1, 1, '2007-04-30 13:10:02', '2019-07-22', 'night', 1, 'cave', 
'0000111122223333', FALSE, FALSE, FALSE, FALSE),
(5, 5, 1, '2007-04-30 13:10:02', '2019-07-22', 'afternoon', 3, 'open', 
'2222444466668888', FALSE, FALSE, FALSE, FALSE),
(6, 5, 3, '2007-04-30 13:10:02', '2019-07-23', 'morning', 2, 'cave', 
'2222444466668888', FALSE, FALSE, FALSE, FALSE),
(7, 5, 3, '2007-04-30 13:10:02', '2019-07-24', 'morning', 2, 'cave', 
'2222444466668888', FALSE, FALSE, FALSE, FALSE);

INSERT INTO DiverBookings VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(1, 2),
(2, 2),
(3, 2),
(1, 3),
(3, 3),
(1, 4),
(5, 5),
(1, 5),
(2, 5),
(3, 5),
(4, 5),
(6, 5),
(7, 5),
(5, 6),
(5, 7);

INSERT INTO DivingSiteReviews VALUES
(1, 3, 1, 3),
(2, 2, 2, 0),
(3, 4, 2, 1),
(4, 3, 2, 2),
(5, 5, 3, 4),
(6, 4, 3, 5),
(7, 1, 3, 2),
(8, 7, 3, 3);

INSERT INTO MonitorReviews VALUES
(1, 1, 1, 2),
(2, 1, 2, 0),
(3, 1, 3, 5),
(4, 5, 5, 1),
(5, 5, 6, 0),
(6, 5, 7, 2);
