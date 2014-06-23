Shelf = require('./shelf')
Q = require('q')

FeedLike = Shelf.Model.extend
  tableName: 'feed_likes'
  idAttribute: 'feed_like_id'
  hasTimestamps: true
  permittedAttributes: [
    'comment', 'feed_like_id', 'feed_id', 'user_id'
  ]

FeedLikes = Shelf.Collection.extend
  model: FeedLike

module.exports = [FeedLike, FeedLikes]