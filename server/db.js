const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function testDatabaseConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('Successfully connected to MySQL database');
    connection.release();
  } catch (error) {
    console.error('Failed to connect to MySQL database:', error);
    process.exit(1);  // Exit the process if unable to connect to the database
  }
}

// Test the connection immediately
testDatabaseConnection();

// Export a function to get the pool, so we can retry the connection if needed
module.exports = {
  getPool: () => pool,
  testConnection: testDatabaseConnection
};