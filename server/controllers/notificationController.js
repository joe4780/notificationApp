// Fetch notifications for a specific user
exports.getUserNotifications = (req, res) => {
  const userId = req.params.userId;
  const query = 'SELECT * FROM notifications WHERE user_id = ?';
  db.query(query, [userId], (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
};

// Fetch all notifications
exports.getAllNotifications = (req, res) => {
  const query = 'SELECT * FROM notifications';
  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
};

// Send a notification
exports.sendNotification = (req, res) => {
  const { message, userIds, expiry_date } = req.body;

  if (!message || !userIds || !userIds.length) {
    return res.status(400).json({ error: 'Invalid data' });
  }

  // Handle expiry_date: if empty, set it to null
  const expiryDate = expiry_date && expiry_date.trim() !== '' ? expiry_date : null;

  Promise.all(userIds.map(userId => {
    return new Promise((resolve, reject) => {
      const query = 'INSERT INTO notifications (user_id, message, expiry_date, is_read, sent_at) VALUES (?, ?, ?, ?, ?)';
      const now = new Date(); // Current timestamp
      db.query(query, [userId, message, expiryDate, false, now], (err, result) => {
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
};
