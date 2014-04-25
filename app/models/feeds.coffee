Shelf = require('./shelf')
Q = require('q')

Feed = Shelf.Model.extend
  tableName: 'feed'
  idAttribute: 'feed_id'
  hasTimestamps: true
  permittedAttributes: [
    'content', 'channel_id', 'channel_type'
  ]

Feeds = Shelf.Collection.extend
  model: Feed

module.exports = [Feed, Feeds]