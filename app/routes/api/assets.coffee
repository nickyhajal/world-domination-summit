_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
Q = require('q')
async = require('async')
get_templates = require('../../processors/templater')

# We clear some items in our redis cache upon start-up
clearCache = ->
	clear = (key) ->
		rds.expire key, 0
	clear('tpls_pages')
	clear('tpls_parts')
	clear('tpls_admin')
	clear('tpls__content')
	clear('tpls__sidebars')

clearCache()

routes = (app) ->

	[User, Users] = require('../../models/users')
	[Event, Events] = require('../../models/events')
	[EventRsvp, EventRsvps] = require('../../models/event_rsvps')
	[Registration, Registrations] = require('../../models/registrations')
	[EventHost, EventHosts] = require('../../models/event_hosts')

	assets =
			expires:
				me: 0
				userobjs: 500
				templates: 800
				content: 120
			get: (req, res, next) ->
				async.each req.query.assets.split(','), (asset, cb) ->
					assets[asset](req)
					.then (rsp) ->
						res.r[asset] = rsp
						cb()
				, ->
					next()
			isExpired: (asset, last) ->	
				expire_ms = assets.expires[assets] * 60 * 1000
				return (+(new Date()) - last) > expire_ms
			redisValue: (value) ->
				if value? and value
					value = JSON.parse(value)
					if typeof value is object
						return value
				return false
			admin_templates: (req) ->
				dfr = Q.defer()
				if req.me
					req.me.getCapabilities()
					.then (me) ->
						get_templates {}, 'admin', (all_tpls) ->
							tpls = {}
							for name,tpl of all_tpls
								name = name.replace('admin_', '')
								if me.hasCapability(name)
									tpls[name] = tpl
							dfr.resolve(tpls)
				else
					dfr.resolve([])
				return dfr.promise
			all_attendees: ->
				dfr = Q.defer()
				rds.get 'all_attendees', (err, atns) ->
					if atns? and atns and typeof JSON.parse(atns) is 'object'
						dfr.resolve(JSON.parse(atns))
					else
						Users.forge()
						.query('where', 'attending14', '1')
						.fetch
							columns: ['user_id', 'first_name', 'last_name', 'user_name', 'distance', 'lat', 'lon', 'pic', 'location']
						.then (attendees) ->
							atns = []
							for atn in attendees.models
								if atn.get('user_name').length is 40
									atn.set('user_name', 'no-profile')
								atns.push atn
							rds.set 'all_attendees', JSON.stringify(atns), (err, rsp) ->
								rds.expire 'all_attendees', 1000, (err, rsp) ->
									dfr.resolve(atns)
				return dfr.promise
			me: (req) ->
				dfr = Q.defer()
				if req.me
					Users.forge().getUser(req.me.get('user_id'))
					.then (user) ->
						user.getAllTickets()
						.then (user) ->
							user.getAnswers()
							.then (user) ->
								user.getInterests()
								.then (user) ->
									user.getConnections()
									.then (user) ->
										user.getFeedLikes()
										.then (user) ->
											user.getRsvps()
											.then (user) ->
												dfr.resolve(user)
				else
					dfr.resolve(false)
				return dfr.promise
			events: (req) ->
				dfr = Q.defer()
				Events.forge()
				.query('where', 'active', '1')
				.fetch()
				.then (rsp) ->
					evs = []
					async.each rsp.models, (ev, cb) ->
						EventHosts.forge()
						.query('where', 'event_id', ev.get('event_id'))
						.fetch()
						.then (rsp) ->
							hosts = []
							for host in rsp.models
								hosts.push host.get('user_id')
							ev.set('hosts', hosts)
							evs.push ev
							cb()
						, (err) ->
							console.err(err)
					, ->
						dfr.resolve(evs)
				, (err) ->
					console.log(err)
				return dfr.promise
			tpls: ->
				get_templates = require('../../processors/templater')
				dfr = Q.defer()
				get_templates {}, 'pages', (tpls) ->
					get_templates tpls, 'parts', (tpls) ->
						get_templates tpls, '_content', (tpls) ->
							get_templates tpls, '_sidebars', (tpls) ->
								dfr.resolve(tpls)
				return dfr.promise
			notifications: ->
				dfr = Q.defer()
				if req.me
					Notifications.forge()
					.query('where', 'user_id', '=', req.me.get('user_id'))
					.query('where', 'read', '=', '0')
					.fetch()
					.then (notifications) ->
						dfr.resolve(notifications.models)
				else
					dfr.resolve([])

				return dfr.promise
			registrations: ->
				dfr = Q.defer()
				Registrations.forge().query('where', 'year', '=', process.year)
				.fetch()
				.then (rsp) ->
					regs = {}
					for reg in rsp.models
						regs[reg.get('user_id')] = '1'
					dfr.resolve(regs)
				return dfr.promise




module.exports = routes