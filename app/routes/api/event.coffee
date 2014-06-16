_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
async = require('async')

routes = (app) ->

	[Event, Events] = require('../../models/events')
	[EventHost, EventHosts] = require('../../models/event_hosts')
	[EventInterest, EventInterests] = require('../../models/event_interests')

	event =
		add: (req, res, next) ->
			if req.me
				post = _.pick req.query, Event::permittedAttributes
				start = moment.utc(process.year+'-07-'+req.query.date+' '+req.query.hour+':'+req.query.minute+':00', 'YYYY-MM-DD HH:mm:ss')
				post.start = start.add('hours', req.query.pm).format('YYYY-MM-DD HH:mm:ss')

				if not post.type?
					post.type = 'meetup'

				post.year = process.yr

				Event.forge(post)
				.save()
				.then (event) ->
					if post.type is 'meetup'
						EventHost.forge({event_id: event.get('event_id'), user_id: req.me.get('user_id')})
						.save()
						.then (host) ->
							if req.query.interests? and req.query.interests.length
								async.each req.query.interests.split(','), (interest, cb) ->
									EventInterest.forge({event_id: event.get('event_id'), interest_id: interest})
									.save()
									.then (interest) ->
										cb()
								, ->
									next()
							else
								next()
						, (err) ->
							console.error(err)
					else
						next()
				, (err) ->
					console.error(err)
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(401)
				next()

		upd: (req, res, next) ->
			if req.me
				post = _.pick req.query, Event::permittedAttributes
				start = moment.utc(process.year+'-07-'+req.query.date+' '+req.query.hour+':'+req.query.minute+':00', 'YYYY-MM-DD HH:mm:ss')
				post.start = start.add('hours', req.query.pm).format('YYYY-MM-DD HH:mm:ss')
				Event.forge({event_id: post.event_id})
				.fetch()
				.then (ev) ->
					EventHost.forge({event_id: post.event_id, user_id: req.me.get('user_id')})
					.fetch()
					.then (host) ->
						if not host 
							req.me.getCapabilities()
							.then ->
								if req.me.hasCapability('schedule')
									ev.set(post)
									.save()
									.then ->
										next()
								else
									res.r.msg = 'You don\'t have permission to do that!'
									res.status(403)
									next()
						else
								ev.set(post)
								.save()
								.then ->
									next()
			else
				res.r.msg = 'You don\'t have permission to do that!'
				res.status(403)
				next()

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

module.exports = routes