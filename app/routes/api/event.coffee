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
				post = _.pick req.query, Event.permittedAttributes
				tk Event.permittedAttributes
				tk Event::permittedAttributes
				tk post
				start = moment.utc(process.year+'-07-'+req.query.date+' '+req.query.hour+':'+req.query.minute+':00', 'YYYY-MM-DD HH:mm:ss')
				if req.query.hour is '12'
					req.query.pm = Math.abs(req.query.pm - 12)
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
				if req.query.hour is '12'
					req.query.pm = Math.abs(req.query.pm - 12)
				tk req.query.pm
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
			if req.me? && req.me.hasCapability('schedule')
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
				res.status(401)
				next()

		get: (req, res, next) ->
			if req.me.hasCapability('schedule')
				events = Events.forge()
				limit = req.query.per_page ? 50
				page = req.query.page ? 1
				active = req.query.active ? 1
				if req.query.type?
					events.query('where', 'type', req.query.type)
				events.query('orderBy', 'event_id',  'DESC')
				events.query('limit', limit)
				events.query('where', 'active', active)
				events.query('where', 'ignored', 0)
				events
				.fetch()
				.then (event) ->
					res.r.events = event.models
					next()
			else
				res.status(401)
				next()

		accept: (req, res, next) ->
			if req.me.hasCapability('schedule')
				Event.forge
					event_id: req.query.event_id
				.fetch()
				.then (model) ->
					model.set('active', 1)
					model.save()
					next()
			else
				res.status(401)
				next()

		reject: (req, res, next) ->
			if req.me.hasCapability('schedule')
				Event.forge
					event_id: req.query.event_id
				.fetch()
				.then (model) ->
					model.set('ignored', 1)
					model.save()
					next()
				, (err) ->
					console.error(err)
			else
				res.status(401)
				next()


module.exports = routes
