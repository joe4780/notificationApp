const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db'); // Importing MySQL connection

// Register a new user
exports.register = (req, res) => {
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
};

// Log in a user
exports.login = (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Invalid data' });
  }

  const query = 'SELECT * FROM users WHERE username = ?';
  db.query(query, [username], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = results[0];

    bcrypt.compare(password, user.password, (err, match) => {
      if (err) {
        console.error('Password comparison error:', err);
        return res.status(500).json({ error: 'Password comparison error' });
      }

      if (!match) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { userId: user.id, role: user.role }, 
        process.env.JWT_SECRET || 'your_jwt_secret', // Using environment variables for JWT secret
        { expiresIn: '1h' }
      );

      return res.status(200).json({
        token,
        userId: user.id,
        role: user.role 
      });
    });
  });
};
