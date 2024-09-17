const mysql = require('mysql2');
require('dotenv').config(); // Load environment variables

// MySQL Connection
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'q4521',
  database: process.env.DB_NAME || 'notification_system'
});

db.connect(err => {
  if (err) {
    console.error('MySQL connection error:', err);
  } else {
    console.log('Connected to MySQL');
  }
});

module.exports = db;
