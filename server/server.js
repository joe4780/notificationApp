const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

// Import controllers
const userController = require('./controllers/userController');
const notificationController = require('./controllers/notificationController');

// Middleware
app.use(cors()); 
app.use(express.json());

// Error handling for asynchronous route handlers
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Routes
app.get('/users', asyncHandler(userController.getUsers));
app.post('/register', asyncHandler(userController.register));
app.post('/login', asyncHandler(userController.login));

// Notification routes
app.post('/notifications', asyncHandler(notificationController.sendNotification));
app.get('/notifications', asyncHandler(notificationController.getNotifications));
app.get('/users/:userId/notifications', asyncHandler(notificationController.getUserNotifications));
app.put('/notifications/:notificationId/read', asyncHandler(notificationController.markNotificationAsRead));

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
});

// Start server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
