_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')

routes = (app) ->

	[Feed, Feeds] = require('../../models/feeds')
	[FeedComment, FeedComments] = require('../../models/feed_comments')
	[FeedLike, FeedLikes] = require('../../models/feed_likes')
	[Notification, Notifications] = require('../../models/notifications')

	feed =
		add: (req, res, next) ->
			if req.me
				post = _.pick req.query, Feed.prototype.permittedAttributes
				post.user_id = req.me.get('user_id')

				# Check if this is a duplicate post
				uniq = moment().format('YYYY-MM-DD HH:mm') + post.content + post.user_id
				post.hash = crypto.createHash('md5').update(uniq).digest('hex')
				Feed.forge
					hash: post.hash

				.fetch()
				.then (existing) ->
					if not existing
						feed = Feed.forge post
						feed
						.save()
						.then (feed) ->
							next()
					else
						res.r.msg = 'You already posted that!'
						res.status(409)
						next()
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(401)
				next()

		add_like: (req, res, next) ->
			if req.me
				post = _.pick req.query, FeedLike::permittedAttributes
				post.user_id = req.me.get('user_id')
				FeedLike.forge(post)
				.save()
				.then (like) ->
					Feed.forge({feed_id: req.query.feed_id})
					.fetch()
					.then (feed) ->
						num_likes = feed.get('num_likes') + 1
						feed.set({num_likes: num_likes})
						.save()
						.then ->
								res.r.num_likes = num_likes
								next()
						, (err) ->
							console.error(err)
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()

		add_comment: (req, res, next) ->
			if req.me
				post = _.pick req.query, FeedComment.prototype.permittedAttributes
				post.user_id = req.me.get('user_id')

				# Check if this is a duplicate post
				uniq = moment().format('YYYY-MM-DD HH:mm') + post.comment + post.user_id
				post.hash = crypto.createHash('md5').update(uniq).digest('hex')
				FeedComment.forge
					hash: post.hash
				.fetch()
				.then (existing) ->
					if not existing
						comment = FeedComment.forge post
						comment
						.save()
						.then (comment) ->
							Feed.forge({feed_id: req.query.feed_id})
							.fetch()
							.then (feed) ->
								feed.set({num_comments: (feed.get('num_comments') + 1)})
								.save()
								.then (feed) ->
										Notification.forge
											user_id: feed.get('user_id')
											notification: req.me.get('first_name')+' '+req.me.get('last_name')+' commented on your post!'
											link: '/dispatch/'+req.query.feed_id
										.save()
										next()
								, (err) ->
									console.error(err)
					else
						res.r.msg = 'You already posted that!'
						res.status(409)
						next()
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()

		upd: (req, res, next) ->
			feed.add(req,res,next)

		del: (req, res, next) ->
			if req.me
				if req.query.feed_id?
					Feed.forge req.query.feed_id
					.fetch()
					.then (feed) ->
						if feed.get('user_id') is req.me.get('user_id')
							feed.destroy()
							.then ->
								next()
				else
					res.r.msg = 'No feed item sent'
					res.status(400)
					next()
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()

		get: (req, res, next) ->
			feeds = Feeds.forge()
			limit = req.query.per_page ? 50
			page = req.query.page ? 1
			if req.query.channel_type is 'user'
				feeds.query('where', 'user_id', '=', req.query.channel_id)
			else if req.query.channel_type isnt 'global'
				feeds.query('where', 'channel_type', '=', req.query.channel_type)
				feeds.query('where', 'channel_id', '=', req.query.channel_id)
			feeds.query('orderBy', 'feed_id',  'DESC')
			feeds.query('limit', limit)
			if req.query.before?
				feeds.query('where', 'feed_id', '<', req.query.before)
			else if req.query.since?
				feeds.query('where', 'feed_id', '>', req.query.since)
			if req.query.user_id
				feeds.query('where', 'user_id', '=', req.query.user_id)
			feeds
			.fetch()
			.then (feed) ->
				res.r.feed_contents = feed.models
				next()
			, (err) ->
				console.error(err)

		get_comments: (req, res, next) ->
			comments = FeedComments.forge()
			comments.query('orderBy', 'feed_comment_id')
			comments.query('where', 'feed_id', '=', req.query.feed_id)
			if req.query.since?
				comments.query('where', 'feed_comment_id', '>', req.query.since)
			comments
			.fetch()
			.then (result) ->
				res.r.comments = result.models
				res.r.num_comments = result.models.length
				next()
			, (err) ->
				console.error(err)

module.exports = routes