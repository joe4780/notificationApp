const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

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

// Register a new user
app.post('/register', (req, res) => {
  const { username, password, role } = req.body;
  if (!username || !password || !role) {
    return res.status(400).json({ error: 'Invalid data' });
  }

  bcrypt.hash(password, 10, (err, hashedPassword) => {
    if (err) {
      return res.status(500).json({ error: 'Password hashing error' });
    }

    const query = 'INSERT INTO users (username, password, role) VALUES (?, ?, ?)';
    db.query(query, [username, hashedPassword, role], (err, result) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to register user' });
      }
      res.status(201).json({ success: true, message: 'User registered' });
    });
  });
});

// Log in a user
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Invalid data' });
  }

  const query = 'SELECT * FROM users WHERE username = ?';
  db.query(query, [username], (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    if (results.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = results[0];
    bcrypt.compare(password, user.password, (err, match) => {
      if (err) {
        return res.status(500).json({ error: 'Password comparison error' });
      }
      if (!match) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign({ userId: user.id, role: user.role }, 'your_jwt_secret', { expiresIn: '1h' });
      res.json({ token, userId: user.id });
    });
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
