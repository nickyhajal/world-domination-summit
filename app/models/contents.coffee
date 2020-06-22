Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
redis = require("redis")
async = require('async')
rds = redis.createClient()

Content = Shelf.Model.extend
  tableName: 'featured_content'
  idAttribute: 'content_id'

Contents = Shelf.Collection.extend
	model: Content
	getFeaturedTweeters: ->
		dfr = Q.defer()
		rds.get 'featured_tweeters', (err, ids) ->
			if ids? and typeof JSON.parse(ids) is 'object'
				dfr.resolve(JSON.parse(ids))
			else
				Contents.forge()
				.query('where', 'type', 'featured_tweet')
				.fetch()
				.then (rsp) ->
					ids = []
					async.each rsp.models, (tweet, cb) ->
						data = JSON.parse(tweet.get('data'))
						[User, Users] = require('./users')
						User.forge({twitter: data.tweeter})
						.fetch()
						.then (user) ->
							if user
								ids.push(user.get('user_id'))
							cb()
					, ->
						rds.set 'featured_tweeters', JSON.stringify(ids), ->
							rds.expire 'featured_tweeters', 300, ->
					  		dfr.resolve(ids)
		return dfr.promise

module.exports = [Content, Contents]
