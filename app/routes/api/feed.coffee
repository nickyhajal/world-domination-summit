_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
_s = require('underscore.string')
async = require('async')

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
								if feed.get('user_id') isnt req.me.get('user_id')
									Notification.forge
										type: 'feed_like'
										channel_type:  feed.get('channel_type')
										channel_id:  feed.get('channel_id')
										user_id: feed.get('user_id')
										content: JSON.stringify
											liker_id: req.me.get('user_id')
											content_str: _s.truncate(feed.get('content'), 100)
										link: '/dispatch/'+feed.get('feed_id')
									.save()
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
					if not existing and post.comment
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
										if feed.get('user_id') isnt req.me.get('user_id')
											Notification.forge
												type: 'feed_comment'
												channel_type:  feed.get('channel_type')
												channel_id:  feed.get('channel_id')
												user_id: feed.get('user_id')
												content: JSON.stringify
													commenter_id: req.me.get('user_id')
													content_str: _s.truncate(feed.get('content'), 100)
												link: '/dispatch/'+feed.get('feed_id')
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
			channel_type = req.query.channel_type
			columns = null

			# Get a users feed
			if channel_type is 'user'
				feeds.query('where', 'user_id', '=', req.query.channel_id)

			# Get a specific feed post
			else if channel_type is 'feed_item'
				feeds.query('where', 'feed_id', '=', req.query.channel_id)

			else if channel_type is 'community'
				feeds.query('where', 'channel_type', '=', 'interest')

			# Get a channel feed
			else if channel_type isnt 'global'
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
			if req.query.include_author?
				feeds.query('join', 'users', 'users.user_id', '=', 'feed.user_id', 'left')
				columns = {columns: ['feed.*', 'first_name', 'last_name', 'user_name', 'pic', 'email']}

			raw_filters = req.query.filters ? {}
			filters = []
			for key,val of raw_filters
				filters.push({name: key, val: val})
			async.each filters, (filter, cb) ->
				if +filter.val
					if filter.name is 'twitter'
						feeds.query('where', 'channel_type', '!=', 'twitter')
						cb()
					if filter.name is 'following'
						req.me.getConnections()
						.then (rsp) ->
							ids = rsp.get('connected_ids')
							if not ids.length
								ids = [0]
							feeds.query('whereIn', 'feed.user_id', ids)
							cb()
					if filter.name is 'communities'
						req.me.getInterests()
						.then (rsp) ->
							interests = rsp.get('interests').join(',')
							meetups = rsp.get('rsvps').join(',')
							feeds.query 'whereRaw', "(`channel_type` != 'interest' OR (`channel_type` = 'interest' AND `channel_id` IN ("+interests+")))"
							cb()
					if filter.name is 'meetups'
						req.me.getRsvps()
						.then (rsp) ->
							meetups = rsp.get('rsvps').join(',')
							feeds.query 'whereRaw', "(`channel_type` != 'meetup' OR (`channel_type` = 'meetup' AND `channel_id` IN ("+meetups+")))"
							cb()
				else
					cb()
			, ->
				feeds
				.fetch(columns)
				.then (feed) ->
					res.r.feed_contents = feed.models
					next()
				, (err) ->
					console.error(err)

		get_comments: (req, res, next) ->
			columns = null
			comments = FeedComments.forge()
			comments.query('orderBy', 'feed_comment_id')
			comments.query('where', 'feed_id', '=', req.query.feed_id)
			if req.query.include_author?
				comments.query('join', 'users', 'users.user_id', '=', 'feed_comments.user_id', 'left')
				columns = {columns: ['feed_comments.*', 'first_name', 'last_name', 'user_name', 'pic', 'email']}
			if req.query.since?
				comments.query('where', 'feed_comment_id', '>', req.query.since)
			comments
			.fetch(columns)
			.then (result) ->
				res.r.comments = result.models
				res.r.num_comments = result.models.length
				next()
			, (err) ->
				console.error(err)

module.exports = routes