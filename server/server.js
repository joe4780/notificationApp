const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// MySQL Connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'q4521',
  database: 'notification_system'
});

db.connect(err => {
  if (err) {
    console.error('MySQL connection error:', err);
  } else {
    console.log('Connected to MySQL');
  }
});

// Root route for basic server check
app.get('/', (req, res) => {
  res.send('Server is up and running');
});

// Route to fetch all users
app.get('/users', (req, res) => {
  const query = 'SELECT id, name FROM users';
  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
});

// Route to fetch notifications for a specific user
app.get('/notifications/:userId', (req, res) => {
  const userId = req.params.userId;
  const query = 'SELECT * FROM notifications WHERE user_id = ?';
  db.query(query, [userId], (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
});

// Route to fetch all notifications
app.get('/notifications', (req, res) => {
  const query = 'SELECT * FROM notifications';
  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
});

// Route to send a notification
app.post('/notifications', (req, res) => {
  const { message, userIds, expiry_date } = req.body;

  if (!message || !userIds || !userIds.length) {
    return res.status(400).json({ error: 'Invalid data' });
  }

  // Handle expiry_date: if empty, set it to null
  const expiryDate = expiry_date && expiry_date.trim() !== '' ? expiry_date : null;

  // Use Promise.all to handle asynchronous operations
  Promise.all(userIds.map(userId => {
    return new Promise((resolve, reject) => {
      const query = 'INSERT INTO notifications (user_id, message, expiry_date, is_read) VALUES (?, ?, ?, ?)';
      db.query(query, [userId, message, expiryDate, false], (err, result) => {
        if (err) {
          console.error('Error inserting notification:', err);
          reject(err);
        } else {
          resolve(result);
        }
      });
    });
  }))
    .then(() => {
      res.status(201).json({ success: true, message: 'Notification sent!' });
    })
    .catch(err => {
      console.error('Error inserting notifications:', err);
      res.status(500).json({ error: 'Failed to insert notifications' });
    });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
