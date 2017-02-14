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

	feed_routes =
		add: (req, res, next) ->
			if req.me
				post = _.pick req.query, Feed.prototype.permittedAttributes
				post.user_id = req.me.get('user_id')

				if _s.trim(post.content).length > 0
					# Check if this is a duplicate post
					if post.channel_type == 'event'
						post.channel_type = 'meetup'
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
								key = post.channel_type+'_'+post.channel_id
								fireRef = process.fire.database().ref().child('feeds')
								.child(key).set((+(new Date())));
								next()
						else
							res.r.msg = 'You already posted that!'
							res.status(409)
							next()
				else
					res.r.msg = "You didn't submit anything!"
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
				.fetch()
				.then (existing) ->
					if (!existing)
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
						Feed.forge({feed_id: req.query.feed_id})
						.fetch()
						.then (feed) ->
							num_likes = feed.get('num_likes')
							res.r.num_likes = num_likes
							next()
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()

		del_like: (req, res, next) ->
			if req.me
				post = _.pick req.query, FeedLike::permittedAttributes
				post.user_id = req.me.get('user_id')
				FeedLike.forge(post)
				.fetch()
				.then (like) ->
					if like?
						like.destroy()
						Feed.forge({feed_id: req.query.feed_id})
						.fetch()
						.then (feed) ->
							num_likes = feed.get('num_likes') - 1
							feed.set({num_likes: num_likes})
							.save()
							.then ->
									res.r.num_likes = num_likes
									next()
							, (err) ->
								console.error(err)
					else
						next()
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(403)
				next()

		get_updates: (req, res, next) ->
			feed_routes.post_count req, res, ->
				if req.query.feed_ids?
					feeds = Feeds.forge()
					feeds.query('whereIn', 'feed.feed_id', req.query.feed_ids)
					feeds.fetch({
						columns: ['feed_id', 'num_comments', 'num_likes']
					})
					.then (rsp) ->
						updates = {}
						for row in rsp.models
							updates['feed_'+row.get('feed_id')] = {num_comments: row.get('num_comments'), num_likes: row.get('num_likes')}
						res.r.updates = updates
						next()
				else
					next()

		add_comment: (req, res, next) ->
			if req.me
				post = _.pick req.query, FeedComment.prototype.permittedAttributes
				post.user_id = req.me.get('user_id')

				# Check if this is a duplicate post
				uniq = moment().format('YYYY-MM-DD HH:mm') + post.comment + post.user_id + post.feed_id
				tk uniq
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
										key = 'comments_'+post.feed_id
										rds.expire key, 0, (err, rsp) ->
										fireRef = process.fire.database().ref().child('feeds')
										.child(key).set((+(new Date())));
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
			feed_routes.add(req,res,next)

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

		post_count: (req, res, next) ->
			id = 'feedquery_'
			cache = true
			if req.query.since?
				if req.query.channel_type?
					id += req.query.channel_type
				else
					id += 'global'
				if req.query.channel_id?
					id += req.query.channel_id
				if req.query.filters?
					id += 'filters_'+JSON.stringify(req.query.filters)
					if req.query.filters['attendees'] == '1' || req.query.filters['meetups'] == '1' || req.query.filters['communities'] == '1'
						cache = false
				id += req.query.since
				rds.get id, (err, feeds) =>
					if feeds? and feeds and typeof JSON.parse(feeds) is 'object'
						dfr.resolve(JSON.parse(feeds))
					else
						feed_routes.get req, res, ->
							count = res.r.feed_contents.length
							res.r.count = count
							delete res.r.feed_contents
							next()
							if cache
								rds.set id, JSON.stringify(count), (err, rsp) ->
									rds.expire id, 5, (err, rsp) ->
			else
				next()
		get: (req, res, next) ->
			feeds = Feeds.forge()
			limit = req.query.per_page ? 50
			page = req.query.page ? 1
			channel_type = req.query.channel_type
			columns = null
			include = ['none']
			if req.me.get("ticket_type") is '360'
				include.push '360'
			if req.me.get('type') is 'ambassador'
				include.push '360'
				include.push 'ambassador'
				include.push 'ambnstaff'
			if req.me.get('type') is 'staff'
				include.push '360'
				include.push 'ambnstaff',
				include.push 'staff'

			#### REMOVE THIS ONCE WE HAVE EVENTS + FILTERS
			feeds.query('where', 'channel_type', '!=', 'meetup')

			feeds.query('whereIn', 'restrict', include)

			# Get a users feed
			if channel_type is 'user'
				feeds.query('where', 'feed.user_id', '=', req.query.channel_id)

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
				feeds.query('where', 'feed.user_id', '=', req.query.user_id)
			feeds.query('join', 'users', 'users.user_id', '=', 'feed.user_id', 'left')
			columns = {columns: ['feed_id', 'feed.created_at', 'content', 'num_comments', 'num_likes', 'channel_id', 'channel_type', 'feed.user_id', 'first_name', 'last_name', 'user_name', 'pic']}
			# feeds.query (qb) =>
			# 	qb.column(qb.knex.raw('CONVERT_TZ(feed.created_at, \'+00:00\',\'-09:00\') as created_at'))

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
						if filter.val is '2'
							feeds.query 'where', 'channel_type', '!=', 'interest'
							cb()
						else
							req.me.getInterests()
							.then (rsp) ->
								interests = rsp.get('interests')
								if interests.length
									interests = interests.join(',')
									feeds.query 'whereRaw', "(`channel_type` != 'interest' OR (`channel_type` = 'interest' AND `channel_id` IN ("+interests+")))"
								cb()
					if filter.name is 'meetups'
						if filter.val is '2'
							feeds.query 'where', 'channel_type', '!=', 'meetup'
							cb()
						else
							if req.me? and req.me
								req.me.getRsvps()
								.then (rsp) ->
									rsvps = rsp.get('rsvps')
									if rsvps.length
										meetups = rsp.get('rsvps').join(',')
										feeds.query 'whereRaw', "(`channel_type` != 'meetup' OR (`channel_type` = 'meetup' AND `channel_id` IN ("+meetups+")))"
									cb()
							else
								cb()
					if filter.name is 'events'
						if filter.val is '2'
							feeds.query 'where', 'channel_type', '!=', 'event'
							cb()
						else
							if req.me? and req.me
								req.me.getRsvps()
								.then (rsp) ->
									rsvps = rsp.get('rsvps')
									if rsvps.length
										rsvps = rsp.get('rsvps').join(',')
										feeds.query 'whereRaw', "(`channel_type` != 'event' OR (`channel_type` = 'event' AND `channel_id` IN ("+rsvps+")))"
									cb()
							else
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
			key = 'comments_'+req.query.feed_id;
			rds.get key, (err, comments) ->
				if comments? and comments and typeof JSON.parse(comments) is 'object'
					res.r.comments = JSON.parse(comments)
					res.r.num_comments = res.r.comments.length
					next()
				else
					columns = null
					comments = FeedComments.forge()
					comments.query('orderBy', 'feed_comment_id')
					comments.query('where', 'feed_id', '=', req.query.feed_id)
					comments.query('join', 'users', 'users.user_id', '=', 'feed_comments.user_id', 'left')
					columns = {columns: ['feed_comments.*', 'first_name', 'last_name', 'user_name', 'pic']}
					if req.query.since?
						comments.query('where', 'feed_comment_id', '>', req.query.since)
					comments
					.fetch(columns)
					.then (result) ->
						res.r.comments = result.models
						res.r.num_comments = result.models.length
						rds.set key, JSON.stringify(result.models), (err, rsp) ->
								rds.expire key, 1000, (err, rsp) ->
						next()
					, (err) ->
						console.error(err)

module.exports = routes

