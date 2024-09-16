package com.example;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.json.JSONObject;

public class App {
    private static final Logger LOGGER = Logger.getLogger(App.class.getName());

    public static void main(String[] args) {
        // Create a connection to the PostgreSQL database
        Connection connection = createConnection();

        if (connection != null) {
            // Successfully connected, now you can execute queries
            LOGGER.info("Successfully connected to the database.");
            // Close the connection when done
            try {

                // Create a statement
                Statement statement = connection.createStatement();

                // Create a table
                String createTableSQL = "CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name VARCHAR(100), email VARCHAR(100) UNIQUE)";
                statement.execute(createTableSQL);
                LOGGER.info("Table 'users' created or already exists.");

                // Generate unique values for name and email
                String uniqueName = generateUniqueName();
                String uniqueEmail = generateUniqueEmail();

                // Insert a unique record
                String insertSQL = "INSERT INTO users (name, email) VALUES ('" + uniqueName + "', '" + uniqueEmail + "')";
                statement.executeUpdate(insertSQL);
                LOGGER.info("Inserted a record into 'users' table: Name = " + uniqueName + ", Email = " + uniqueEmail);

                // Read the records
                String selectSQL = "SELECT id, name, email FROM users";
                ResultSet resultSet = statement.executeQuery(selectSQL);

                // Process the result set
                while (resultSet.next()) {
                    int id = resultSet.getInt("id");
                    String name = resultSet.getString("name");
                    String email = resultSet.getString("email");
                    LOGGER.info("User ID: " + id + ", Name: " + name + ", Email: " + email);
                }

                // Close the statement and result set
                resultSet.close();
                statement.close();

                connection.close();
            } catch (SQLException e) {
                LOGGER.log(Level.SEVERE, "Error while closing the connection.", e);
            }
        }
    }

    // Generate a unique name using UUID
    public static String generateUniqueName() {
        return "User-" + UUID.randomUUID().toString();
    }

    // Generate a unique email using UUID
    public static String generateUniqueEmail() {
        return "user-" + UUID.randomUUID().toString() + "@example.com";
    }

    public static Connection createConnection() {
        try {
            // Get the JSON secret from environment variable DB_SECRET
            String dbSecretJson = System.getenv("DB_SECRET");

            if (dbSecretJson == null || dbSecretJson.isEmpty()) {
                LOGGER.severe("DB_SECRET environment variable is not set or is empty!");
                return null;
            }

            // Parse the JSON string to extract the database connection details
            JSONObject secret = new JSONObject(dbSecretJson);
            String dbHost = secret.getString("host");
            String dbPort = secret.getString("port");
            String dbName = secret.getString("dbname");
            String dbUser = secret.getString("username");
            String dbPassword = secret.getString("password");

            // Construct the JDBC URL
            String jdbcUrl = "jdbc:postgresql://" + dbHost + "/" + dbName;

            // Establish the connection
            return DriverManager.getConnection(jdbcUrl, dbUser, dbPassword);
        } catch (SQLException e) {
            LOGGER.log(Level.SEVERE, "Error connecting to the database.", e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error parsing the database credentials.", e);
        }

        return null;
    }
}
