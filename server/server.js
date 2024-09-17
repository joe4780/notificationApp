const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const db = require('./db'); // Importing the MySQL connection
const userController = require('./controllers/userController'); // Importing user controller
const notificationController = require('./controllers/notificationController'); // Importing notification controller

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Root route for basic server check
app.get('/', (req, res) => {
  res.send('Server is up and running');
});

// User routes
app.post('/register', userController.register);
app.post('/login', userController.login);

// Notification routes
app.get('/notifications/:userId', notificationController.getUserNotifications);
app.get('/notifications', notificationController.getAllNotifications);
app.post('/notifications', notificationController.sendNotification);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
