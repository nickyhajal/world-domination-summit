Shelf = require('./shelf')

Notification = Shelf.Model.extend
  tableName: 'notifications'
  idAttribute: 'notification_id'
  hasTimestamps: true
  permittedAttributes: [
  	'notification_id', 'user_id', 'notification', 'read', 'emailed'
  ]

Notifications = Shelf.Collection.extend
  model: Notification
  process: ->
  	Notifictions.forge()
  	.query('where', 'emailed', '0')
  	.query('where', 'read', '0')
  	.query('orderBy', 'user_id')
  	.fetch()
  	.then (rsp) ->
  		user_id = 0
  		for notification in rsp.models
  			x = 1




module.exports = [Notification, Notifications]