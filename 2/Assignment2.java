import java.net.URL;
import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;

public class Assignment2 {

    // A connection to the database
    Connection connection;

    // Can use if you wish: seat letters
    List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

    Assignment2() throws SQLException {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    /**
     * Connects and sets the search path.
     *
     * Establishes a connection to be used for this session, assigning it to the
     * instance variable 'connection'. In addition, sets the search path to
     * 'air_travel, public'.
     *
     * @param url      the url for the database
     * @param username the username to connect to the database
     * @param password the password to connect to the database
     * @return true if connecting is successful, false otherwise
     */
    public boolean connectDB(String URL, String username, String password) {
        // Implement this method!
        try {
            connection = DriverManager.getConnection(URL, username, password);
            if (connection.isValid(3) == true) {
                String queryString = "SET SEARCH_PATH TO air_travel, public;";
                PreparedStatement pStatement = connection.prepareStatement(queryString);
                pStatement.executeUpdate();
                return true;
            } else {
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Closes the database connection.
     *
     * @return true if the closing was successful, false otherwise
     */
    public boolean disconnectDB() {
        try {
            connection.close();
            if (connection.isClosed()) {
                return true;
            } else {
                return false;
            }
        } catch (SQLException e) {
            return false;
        }
    }

    /* ======================= Airline-related methods ======================= */

    /**
     * Attempts to book a flight for a passenger in a particular seat class. Does so
     * by inserting a row into the Booking table.
     *
     * Read handout for information on how seats are booked. Returns false if seat
     * can't be booked, or if passenger or flight cannot be found.
     *
     * 
     * @param passID    id of the passenger
     * @param flightID  id of the flight
     * @param seatClass the class of the seat (economy, business, or first)
     * @return true if the booking was successful, false otherwise.
     */
    public boolean bookSeat(int passID, int flightID, String seatClass) {
        // Define variables
        String queryString;
        PreparedStatement pStatement;
        ResultSet rs;
        Integer id;

        // Check that flight exists
        Boolean flightExists = false;
        try {
            queryString = "SELECT * FROM flight;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                id = rs.getInt("id");
                // Iterate through all flights and check if IDs match
                if (id == flightID) {
                    flightExists = true;
                    break;
                }
            }
            System.out.println("flightExists: " + flightExists);
            // If no matching IDs were found, then flight does not exist
            if (flightExists == false) {
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        // Check that passenger exists
        Boolean passengerExists = false;
        try {
            queryString = "SELECT * FROM passenger;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                id = rs.getInt("id");
                // Iterate through all passengers and check if IDs match
                if (id == passID) {
                    passengerExists = true;
                    break;
                }
            }
            System.out.println("passengerExists: " + passengerExists);
            // If no matching IDs were found, then passenger does not exist
            if (passengerExists == false) {
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        // Check that flight has not already occurred
        try {
            java.sql.Timestamp scheduledDeparture = null;

            queryString = "SELECT s_dep FROM flight WHERE id = ?;";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                scheduledDeparture = rs.getTimestamp("s_dep");
            }
            System.out.println("scheduledDeparture: " + scheduledDeparture);
            if (getCurrentTimeStamp().compareTo(scheduledDeparture) > 0) {
                System.out.println("Trying to book an old flight!");
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        // Check that flight is not already full
        // Get number of occupied seats in each class for all flight IDs along
        // with the number of available seats in each seat class
        Integer economyCapacity = -1;
        Integer businessCapacity = -1;
        Integer firstCapacity = -1;
        Integer classOccupied = -1;
        Integer seatsAvailable = -1;
        Integer maxID = 1;

        try {
            // Get number of occupied seats for specific flight and seat class
            switch (seatClass) {
                case "economy":
                    queryString = "SELECT count(*) as occupied FROM booking "
                            + "WHERE flight_id = ? AND seat_class = 'economy'";
                    break;
                case "business":
                    queryString = "SELECT count(*) as occupied FROM booking "
                            + "WHERE flight_id = ? AND seat_class = 'business'";
                    break;
                case "first":
                    queryString = "SELECT count(*) as occupied FROM booking "
                            + "WHERE flight_id = ? AND seat_class = 'first'";
                    break;
                default:
                    break;
            }
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();

            while (rs.next()) {
                classOccupied = rs.getInt("occupied");
            }

            // Get capacity for all classes in specific flight
            queryString = "SELECT capacity_economy AS capacity " + "FROM flight JOIN plane "
                    + "ON flight.plane = plane.tail_number WHERE flight.id = ?;";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                economyCapacity = rs.getInt("capacity");
            }

            queryString = "SELECT capacity_business AS capacity " + "FROM flight JOIN plane "
                    + "ON flight.plane = plane.tail_number WHERE flight.id = ?;";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                businessCapacity = rs.getInt("capacity");
            }

            queryString = "SELECT capacity_first AS capacity " + "FROM flight JOIN plane "
                    + "ON flight.plane = plane.tail_number WHERE flight.id = ?;";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                firstCapacity = rs.getInt("capacity");
            }

            // Allow overbooking for economy
            economyCapacity += 10;

            // Calculate number of available seats
            switch (seatClass) {
                case "economy":
                    seatsAvailable = economyCapacity - classOccupied;
                    break;
                case "business":
                    seatsAvailable = businessCapacity - classOccupied;
                    break;
                case "first":
                    seatsAvailable = firstCapacity - classOccupied;
                    break;
                default:
                    break;
            }

            if (seatsAvailable <= 0) {
                return false;
            }

            // Find max ID from booking table
            queryString = "SELECT max(id) as max FROM booking;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();

            while (rs.next()) {
                // If booking is empty, getInt returns 0 for NULL values
                // Since we are adding 1 before insertion, this works out
                maxID = rs.getInt("max");
            }

            // Get price for specific flight and seat class
            Float price = (float) -1;
            switch (seatClass) {
                case "economy":
                    queryString = "SELECT economy AS price FROM price WHERE flight_id = ?;";
                    break;
                case "business":
                    queryString = "SELECT business AS price FROM price WHERE flight_id = ?;";
                    break;
                case "first":
                    queryString = "SELECT first AS price FROM price WHERE flight_id = ?;";
                    break;
                default:
                    break;
            }
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                price = rs.getFloat("price");
            }

            // Book flight
            Integer newRow = -1;
            String newLetter = "Z";
            // Handle case for overbooking economy
            if (seatClass == "economy" && economyCapacity - classOccupied <= 10) {
                switch (seatClass) {
                    case "economy":
                        queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'economy', ?, ?);";
                        break;
                    case "business":
                        queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'business', ?, ?);";
                        break;
                    default:
                        queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'first', ?, ?);";
                        break;
                }
                pStatement = connection.prepareStatement(queryString);
                pStatement.setInt(1, maxID + 1);
                pStatement.setInt(2, passID);
                pStatement.setInt(3, flightID);
                pStatement.setTimestamp(4, getCurrentTimeStamp());
                pStatement.setFloat(5, price);
                pStatement.setNull(6, 0);
                pStatement.setNull(7, 0);
                id = pStatement.executeUpdate();
                System.out.println("executeUpdate: " + id);

                // Check that insert worked
                queryString = "SELECT * FROM booking;";
                pStatement = connection.prepareStatement(queryString);
                rs = pStatement.executeQuery();
                while (rs.next()) {
                    System.out.println("id: " + rs.getInt("id") + " pass_id: " + rs.getInt("pass_id") + " flight_id: "
                            + rs.getInt("flight_id") + " datetime: " + rs.getTimestamp("datetime") + " price: "
                            + rs.getInt("price") + " seat_class: " + rs.getString("seat_class") + " row: "
                            + rs.getInt("row") + " letter: " + rs.getString("letter"));
                }

                return true;
            }

            // Get number of people that booked economy, business, and first classes
            Integer economyOccupied = -1;
            Integer businessOccupied = -1;
            Integer firstOccupied = -1;

            queryString = "SELECT count(*) as occupied FROM booking "
                    + "WHERE flight_id = ? AND seat_class = 'economy';";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                economyOccupied = rs.getInt("occupied");
            }

            queryString = "SELECT count(*) as occupied FROM booking "
                    + "WHERE flight_id = ? AND seat_class = 'business';";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                businessOccupied = rs.getInt("occupied");
            }

            queryString = "SELECT count(*) as occupied FROM booking " + "WHERE flight_id = ? AND seat_class = 'first';";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                firstOccupied = rs.getInt("occupied");
            }

            // Calculate new row and seat letter
            Integer newLetterIndex;
            switch (seatClass) {
                case "first":
                    newRow = (firstOccupied / 6) + 1;
                    newLetterIndex = firstOccupied % 6;
                    newLetter = seatLetters.get(newLetterIndex);
                    break;
                case "business":
                    newRow = ((firstCapacity / 6) + 1) + 1 + (businessOccupied / 6);
                    newLetterIndex = businessOccupied % 6;
                    newLetter = seatLetters.get(newLetterIndex);
                    break;
                case "economy":
                    newRow = ((firstCapacity / 6) + 1) + 1 + (businessCapacity / 6) + 1 + (economyOccupied / 6);
                    newLetterIndex = economyOccupied % 6;
                    newLetter = seatLetters.get(newLetterIndex);
                    break;
                default:
                    break;
            }

            // Finally add booking
            if (newRow == -1 || newLetter == "Z") {
                return false;
            }

            switch (seatClass) {
                case "economy":
                    queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'economy', ?, ?);";
                    break;
                case "business":
                    queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'business', ?, ?);";
                    break;
                default:
                    queryString = "INSERT INTO booking VALUES (?, ?, ?, ?, ?, 'first', ?, ?);";
                    break;
            }
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, maxID + 1);
            pStatement.setInt(2, passID);
            pStatement.setInt(3, flightID);
            pStatement.setTimestamp(4, getCurrentTimeStamp());
            pStatement.setFloat(5, price);
            pStatement.setInt(6, newRow);
            pStatement.setString(7, newLetter);
            pStatement.executeUpdate();

            System.out.println("flightID: " + flightID);
            System.out.println("seatClass: " + seatClass);
            System.out.println("classOccupied: " + classOccupied);
            System.out.println("economyCapacity: " + economyCapacity);
            System.out.println("businessCapacity: " + businessCapacity);
            System.out.println("firstCapacity: " + firstCapacity);
            System.out.println("seatsAvailable: " + seatsAvailable);
            System.out.println("maxID: " + maxID);
            System.out.println("price: " + price);
            System.out.println("newRow: " + newRow);
            System.out.println("newLetter: " + newLetter);

            // Check that insert worked
            queryString = "SELECT * FROM booking;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                System.out.println("id: " + rs.getInt("id") + " pass_id: " + rs.getInt("pass_id") + " flight_id: "
                        + rs.getInt("flight_id") + " datetime: " + rs.getTimestamp("datetime") + " price: "
                        + rs.getInt("price") + " seat_class: " + rs.getString("seat_class") + " row: "
                        + rs.getInt("row") + " letter: " + rs.getString("letter"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        return false;
    }

    /**
     * Attempts to upgrade overbooked economy passengers to business class or first
     * class (in that order until each seat class is filled). Does so by altering
     * the database records for the bookings such that the seat and seat_class are
     * updated if an upgrade can be processed.
     *
     * Upgrades should happen in order of earliest booking timestamp first.
     *
     * If economy passengers left over without a seat (i.e. more than 10 overbooked
     * passengers or not enough higher class seats), remove their bookings from the
     * database.
     * 
     * @param flightID The flight to upgrade passengers in.
     * @return the number of passengers upgraded, or -1 if an error occured.
     */
    public int upgrade(int flightID) {
        // Implement this method!
        String economyQuery, businessQuery, firstQuery, planeQuery;
        PreparedStatement economyStatement, businessStatement, firstStatement;
        PreparedStatement planeStatement;
        ResultSet economyResult, businessResult, firstResult, planeResult;
        Boolean flightExists;
        String queryString;
        PreparedStatement pStatement;
        ResultSet rs;
        Integer id, firstCapacity = 0, businessCapacity = 0;
        Integer firstBooked = 0, businessBooked = 0;
        Integer firstAvailable = 0, businessAvailable = 0;
        Integer alphaNumeric, rowNumber;
        String seatLetter = "XXX";
        Integer i, firstBusinessRow, lastBookedBNumber, firstAvailableBNumber;
        Integer lastAvailableBNumber, lastBookedFNumber, firstAvailableFNumber;
        Integer lastAvailableFNumber;
        Integer overbookedCount = 0;
        Integer currentSeat = 0, assigned = 0;
        PreparedStatement updateBusinessStatement, updateFirstStatement;
        String updateBusinessQuery, updateFirstQuery;

        // Check that flight exists
        flightExists = false;
        try {
            queryString = "SELECT * FROM flight;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                id = rs.getInt("id");
                // Iterate through all flights and check if IDs match
                if (id == flightID) {
                    flightExists = true;
                    break;
                }
            }
            System.out.println("flightExists:");
            System.out.println(flightExists);
            // If no matching IDs were found, then flight does not exist
            if (flightExists == false) {
                return -1;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }
	
        // Check that flight has not already occurred
        try {
            java.sql.Timestamp scheduledDeparture = null;

            queryString = "SELECT s_dep FROM flight WHERE id = ?;";
            pStatement = connection.prepareStatement(queryString);
            pStatement.setInt(1, flightID);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                scheduledDeparture = rs.getTimestamp("s_dep");
            }
            System.out.println("scheduledDeparture: " + scheduledDeparture);
            if (getCurrentTimeStamp().compareTo(scheduledDeparture) > 0) {
                System.out.println("Trying to book an old flight!");
                return -1;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }


        try {
            // Get overbooked economy bookings from given flight id (up to 10)
            // Order by earliest date
            economyQuery = "SELECT * FROM booking " + "WHERE seat_class = 'economy' AND row is NULL "
                    + "AND letter is NULL AND flight_id = ? " + "ORDER BY datetime ASC;";
            // Set variable using prepared statement
            economyStatement = connection.prepareStatement(economyQuery, ResultSet.TYPE_SCROLL_SENSITIVE,
                    ResultSet.CONCUR_UPDATABLE);
            economyStatement.setInt(1, flightID);
            economyResult = economyStatement.executeQuery();
            if (!economyResult.next()) {
                // No economy passengers to upgrade
                System.out.println("No overbooked economy passengers. Exiting...");
                return -1;
            }
            // Reset cursor if not empty
            else {
                economyResult.beforeFirst();
            }

            while (economyResult.next()) {
                overbookedCount = overbookedCount + 1;
            }
            economyResult.beforeFirst();
            System.out.println("Overbooked economy pax: " + overbookedCount);

            // Get # business class bookings for given flight
            businessQuery = "SELECT count(*) as numBusiness FROM booking "
                    + "WHERE seat_class = 'business' AND flight_id = ? " + "GROUP BY flight_id;";
            businessStatement = connection.prepareStatement(businessQuery);
            businessStatement.setInt(1, flightID);
            businessResult = businessStatement.executeQuery();
            while (businessResult.next()) {
                businessBooked = businessResult.getInt("numBusiness");

            }
            System.out.println("Business class bookings: " + businessBooked);

            // Get # first class bookings for given flight
            firstQuery = "SELECT count(*) as numFirst FROM booking " + "WHERE seat_class = 'first' AND flight_id = ? "
                    + "GROUP BY flight_id;";
            firstStatement = connection.prepareStatement(firstQuery);
            firstStatement.setInt(1, flightID);
            firstResult = firstStatement.executeQuery();
            while (firstResult.next()) {
                firstBooked = firstResult.getInt("numFirst");
            }
            System.out.println("First class bookings: " + firstBooked);

            // Get the capacities of the plane being used for this flight
            planeQuery = "SELECT capacity_economy, capacity_business, " + "capacity_first FROM flight JOIN plane "
                    + "ON flight.plane = plane.tail_number " + "WHERE id = ?;";
            planeStatement = connection.prepareStatement(planeQuery);
            planeStatement.setInt(1, flightID);
            planeResult = planeStatement.executeQuery();
            while (planeResult.next()) {
                firstCapacity = planeResult.getInt("capacity_first");
                businessCapacity = planeResult.getInt("capacity_business");
                System.out.println("Business class capacity: " + businessCapacity);
                System.out.println("First class capacity: " + firstCapacity);

            }

            // get available upgrade seats
            // first class seats available
            // firstCapacity - count(firstClass) = free first seats
            // seatNum = row*6+alphaNumeric

            firstAvailable = firstCapacity - firstBooked;
            System.out.println("Available first class seats: " + firstAvailable);
            businessAvailable = businessCapacity - businessBooked;
            System.out.println("Available business class seats: " + businessAvailable);

            // round up to nearest multiple of 6 to get first b row
            firstBusinessRow = (((firstCapacity + 5) / 6 * 6) / 6) + 1;
            // linear seat number for last booked business passenger
            lastBookedBNumber = ((firstBusinessRow - 1) * 6) + businessBooked;
            // first available seat for economy upgrades in business
            firstAvailableBNumber = lastBookedBNumber + 1;
            // last possible seat for economy upgrades in business
            lastAvailableBNumber = firstAvailableBNumber + businessAvailable - 1;

            // linear seat number for last booked first class passenger
            lastBookedFNumber = firstBooked;
            // first available seat for economy upgrades in first class
            firstAvailableFNumber = lastBookedFNumber + 1;
            // last possible seat for economy upgrades in first class
            lastAvailableFNumber = firstAvailableFNumber + firstAvailable - 1;

            // if some business seats available, assign
            if (businessAvailable > 0) {
                currentSeat = firstAvailableBNumber;
                assigned = 0;
                while (economyResult.next() && assigned < 10 && currentSeat <= lastAvailableBNumber) {

                    rowNumber = (currentSeat / 6) + 1;
                    alphaNumeric = currentSeat % 6;

                    if (alphaNumeric == 1) {
                        seatLetter = "A";
                    }
                    if (alphaNumeric == 2) {
                        seatLetter = "B";
                    }
                    if (alphaNumeric == 3) {
                        seatLetter = "C";
                    }
                    if (alphaNumeric == 4) {
                        seatLetter = "D";
                    }
                    if (alphaNumeric == 5) {
                        seatLetter = "E";
                    }
                    if (alphaNumeric == 0) {
                        seatLetter = "F";
                    }
                    System.out.println("Assign booking for passenger ID " + economyResult.getInt("pass_id") + ": "
                            + Integer.toString(rowNumber) + seatLetter);

                    updateBusinessQuery = "UPDATE booking " + "SET row = ?, letter = ?, seat_class = 'business' " + "WHERE id = ?;";
                    // Set variable using prepared statement
                    updateBusinessStatement = connection.prepareStatement(updateBusinessQuery);
                    updateBusinessStatement.setInt(1, rowNumber);
                    updateBusinessStatement.setString(2, seatLetter);
                    updateBusinessStatement.setInt(3, economyResult.getInt("id"));
                    updateBusinessStatement.executeUpdate();


                    // delete the assigned row from our overbooking result set
                    // economyResult.deleteRow();

                    assigned = assigned + 1;
                    currentSeat = currentSeat + 1;
                }
            }

	    economyResult.previous();


            // if some first class seats available, assign
            if (firstAvailable > 0) {
                currentSeat = firstAvailableFNumber;
                while (economyResult.next() && assigned < 10 && currentSeat <= lastAvailableFNumber) {

                    rowNumber = (currentSeat / 6) + 1;
                    alphaNumeric = currentSeat % 6;

                    if (alphaNumeric == 1) {
                        seatLetter = "A";
                    }
                    if (alphaNumeric == 2) {
                        seatLetter = "B";
                    }
                    if (alphaNumeric == 3) {
                        seatLetter = "C";
                    }
                    if (alphaNumeric == 4) {
                        seatLetter = "D";
                    }
                    if (alphaNumeric == 5) {
                        seatLetter = "E";
                    }
                    if (alphaNumeric == 0) {
                        seatLetter = "F";
                    }
                    System.out.println("Assign booking for passenger ID " + economyResult.getInt("pass_id") + ": "
                            + Integer.toString(rowNumber) + seatLetter);

                    updateFirstQuery = "UPDATE booking " + "SET row = ?, letter = ?, seat_class = 'first' " + "WHERE id = ?;";
                    // Set variable using prepared statement
                    updateFirstStatement = connection.prepareStatement(updateFirstQuery);
                    updateFirstStatement.setInt(1, rowNumber);
                    updateFirstStatement.setString(2, seatLetter);
                    updateFirstStatement.setInt(3, economyResult.getInt("id"));
                    updateFirstStatement.executeUpdate();

                    // delete the assigned row from our overbooking result set
                    // economyResult.deleteRow();

                    assigned = assigned + 1;
                    currentSeat = currentSeat + 1;

                }

            }

            System.out.println("Total upgrades: " + assigned);

            queryString = "SELECT * FROM booking;";
            pStatement = connection.prepareStatement(queryString);
            rs = pStatement.executeQuery();
            while (rs.next()) {
                System.out.println("id: " + rs.getInt("id") + " pass_id: " + rs.getInt("pass_id") + " flight_id: "
                        + rs.getInt("flight_id") + " datetime: " + rs.getTimestamp("datetime") + " price: "
                        + rs.getInt("price") + " seat_class: " + rs.getString("seat_class") + " row: "
                        + rs.getInt("row") + " letter: " + rs.getString("letter"));
            }

            return assigned;

        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }

        // return -1;
    }

    /* ----------------------- Helper functions below ------------------------- */

    // A helpful function for adding a timestamp to new bookings.
    // Example of setting a timestamp in a PreparedStatement:
    // ps.setTimestamp(1, getCurrentTimeStamp());

    /**
     * Returns a SQL Timestamp object of the current time.
     * 
     * @return Timestamp of current time.
     */
    private java.sql.Timestamp getCurrentTimeStamp() {
        java.util.Date now = new java.util.Date();
        return new java.sql.Timestamp(now.getTime());
    }

    // Add more helper functions below if desired.

    /* ----------------------- Main method below ------------------------- */

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
        System.out.println("Running the code!");
        Assignment2 classTest;
        try {
            classTest = new Assignment2();
            String url = "jdbc:postgresql://localhost:5432/csc343h-dingdani";
            String username = "dingdani";
            String password = "";
            classTest.connectDB(url, username, password);

            // Test methods
            //classTest.bookSeat(1, 5, "economy");
	    classTest.upgrade(10);

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
