import 'package:mysql1/mysql1.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets

class DatabaseService {
  // Function to establish connection to the database
  static Future<MySqlConnection> getConnection() async {
    var settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: 'password',
      db: 'car_wash',
    );
    return await MySqlConnection.connect(settings);
  }

  // Function to check user credentials
  static Future<bool> authenticateUser(
      String loginInput, String password, bool isEmail) async {
    MySqlConnection conn = await getConnection();
    try {
      // Prepare the query based on the login method
      String query;
      if (isEmail) {
        query =
            'SELECT * FROM users WHERE email = ? AND password = ?'; // Adjust your table name and fields
      } else {
        query =
            'SELECT * FROM users WHERE phone = ? AND password = ?'; // Adjust your table name and fields
      }

      // Execute the query
      var results = await conn.query(query, [loginInput, password]);
      return results.isNotEmpty; // Returns true if user exists
    } catch (e) {
      print('Error authenticating user: $e');
      return false;
    } finally {
      await conn.close(); // Always close the connection
    }
  }

  // Function to execute SQL scripts from a file
  static Future<void> executeSqlFile(String filePath) async {
    try {
      // Load the SQL file content
      String sqlScript = await rootBundle.loadString(filePath);

      MySqlConnection conn = await getConnection();

      // Split the script by semicolons to execute multiple queries
      List<String> queries = sqlScript.split(';');

      for (String query in queries) {
        if (query.trim().isNotEmpty) {
          await conn.query(query);
        }
      }

      print('SQL script executed successfully');
      await conn.close();
    } catch (e) {
      print('Error executing SQL script: $e');
    }
  }
}
