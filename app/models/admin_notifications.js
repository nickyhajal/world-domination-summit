const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const AdminNotification = Shelf.Model.extend({
  tableName: 'admin_notifications',
  idAttribute: 'admin_notification_id',
  hasTimestamps: true,
});

const AdminNotifications = Shelf.Collection.extend({
  model: AdminNotification,
});

module.exports = [AdminNotification, AdminNotifications];
