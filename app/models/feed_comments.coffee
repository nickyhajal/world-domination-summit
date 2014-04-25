Shelf = require('./shelf')
Q = require('q')

FeedComment = Shelf.Model.extend
  tableName: 'feed_comments'
  idAttribute: 'feed_comment_id'
  hasTimestamps: true
  permittedAttributes: [
    'comment', 'feed_id', 'user_id', 'comment', 'hash'
  ]

FeedComments = Shelf.Collection.extend
  model: FeedComment

module.exports = [FeedComment, FeedComments]