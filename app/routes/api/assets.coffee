_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
Q = require('q')
async = require('async')
get_templates = require('../../processors/templater')
moment = require('moment')

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
	[EventInterest, EventInterests] = require('../../models/event_interests')
	[Speaker, Speakers] = require('../../models/speakers')
	[Interest, Interests] = require('../../models/interests')
	[RaceTask, RaceTasks] = require('../../models/racetasks')
	[Achievement, Achievements] = require('../../models/achievements')
	[Place, Places] = require('../../models/places')

	assets =

			# How long before an asset expires (in minutes)
			expires:
				me: 0
				tpls: 60
				all_attendees: 60
				speakers: 300
				interests: 5
				events: 5
				ranks: 1
				tasks: 5
				places: 300
				achievements: 0
				admin_templates: 0

			get: (req, res, next) ->
				start = +(new Date())
				tracker = req.query.tracker ? {}
				async.each req.query.assets.split(','), (asset, cb) =>
					assetStart = +(new Date())
					last = tracker[asset] ? 0
					now = Math.floor(+(new Date()) / 1000)
					if process.env.NODE_ENV is 'production'
						expires = (+last + +(assets.expires[asset] * 60))
					else
						expires = 0
					expired = expires < now
					if assets[asset]? and expired
						assets[asset](req)
						.then (rsp) ->
							res.r[asset] = rsp
							#tk 'Grabbing '+asset+ ' took: '+(+(new Date()) - assetStart)+' milliseconds'
							cb()
					else
						cb()
				, ->
					#tk 'Asset grab took: '+(+(new Date()) - start)+' milliseconds'
					next()

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
								if me.hasCapability(name) or name is 'index'
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
						.query('where', 'attending'+process.yr, '1')
						.fetch
							columns: ['user_id', 'first_name', 'last_name', 'user_name', 'distance', 'lat', 'lon', 'location']
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
					Users.forge().getUser(req.me.get('user_id'), true)
					.then (user) ->
						user.getMe()
						.then (user) ->
							user = user.toJSON()
							delete user.password
							delete user.hash
							delete user.tickets
							dfr.resolve(user)
				else
					dfr.resolve(false)
				return dfr.promise

			tasks: (req) ->
				dfr = Q.defer()
				rds.get 'tasks', (err, tasks) ->
					if tasks? and tasks and typeof JSON.parse(tasks) is 'object'
						dfr.resolve(JSON.parse(tasks))
					else
						RaceTasks.forge()
						.fetch()
						.then (rsp) ->
							dfr.resolve(rsp.models)
							rds.set 'tasks', JSON.stringify(rsp.models), ->
								rds.expire 'tasks', 5000
				return dfr.promise

			ranks: (req) ->
				dfr = Q.defer()
				rds.get 'ranks', (err, ranks) ->
					if ranks? and ranks and typeof JSON.parse(ranks) is 'object'
						dfr.resolve(JSON.parse(ranks))
					else
						Users.forge()
						.query('where', 'attending'+process.yr, '1')
						.query('where', 'points', '>', '0')
						.query('orderBy', 'points', 'desc')
						.fetch({columns: ['user_id', 'points']})
						.then (rsp) ->
							dfr.resolve(rsp.models)
							rds.set 'ranks', JSON.stringify(rsp.models), ->
								rds.expire 'ranks', 60
						, (err) ->
							console.error(err)
				return dfr.promise

			speakers: (req) ->
				dfr = Q.defer()
				rds.get 'speakers', (err, spks) ->
					if spks? and spks and typeof JSON.parse(spks) is 'object'
						dfr.resolve(JSON.parse(spks))
					else
						Speakers.forge().getByType()
						.then (speakers) ->
							dfr.resolve(speakers)
							rds.set 'speakers', JSON.stringify(speakers), (err, rsp) ->
								rds.expire 'speakers', 10000
				return dfr.promise

			places: (req) ->
				dfr = Q.defer()
				rds.get 'places', (err, places) ->
					if places? and places and typeof JSON.parse(places) is 'object'
						dfr.resolve(JSON.parse(places))
					else
						Places.forge()
						.fetch()
						.then (rsp) ->
							places = rsp.models
							dfr.resolve(places)
							rds.set 'places', JSON.stringify(places), (err, rsp) ->
								rds.expire 'places', 10000
				return dfr.promise

			achievements: (req) ->
				dfr = Q.defer()
				if req.me
					req.me.getAchievedTasks()
					.then (achs) ->
						dfr.resolve(achs.toJSON())
				else
					dfr.resolve([])
				return dfr.promise
			interests: (req) ->
				dfr = Q.defer()
				rds.get 'interests', (err, interests) ->
					if interests? and interests and typeof JSON.parse(interests) is 'object'
						dfr.resolve(JSON.parse(interests))
					else
						Interests.forge().fetch()
						.then (interests) ->
							dfr.resolve(interests)
							rds.set 'interests', JSON.stringify(interests), (err, rsp) ->
								rds.expire 'interests', 10000
				Interests.forge().fetch()
				.then (interests) ->
					dfr.resolve(interests)
				return dfr.promise

			events: (req) ->
				dfr = Q.defer()
				rds.get 'events', (err, events) ->

					if events? and events and typeof JSON.parse(events) is 'object'
						dfr.resolve(JSON.parse(events))
					else
						Events.forge()
						.query('where', 'active', '1')
						.query('where', 'year', process.yr)
						.query('orderBy', 'start')
						.fetch()
						.then (rsp) ->
							evs = []
							async.each rsp.models, (ev, cb) ->
								ev.set('startStr', moment(ev.get('start')).format('h:mm a'))
								ev.set('dayStr', moment(ev.get('start')).format('dddd[,] MMMM Do'))
								ev.set('startDay', moment(ev.get('start')).format('YYYY-MM-DD'))
								EventInterests.forge()
								.query('where', 'event_id', ev.get('event_id'))
								.fetch()
								.then (rsp) ->
									interests = []
									for interest in rsp.models
										interests.push interest.get('interest_id')
									ev.set('ints', interests)
									EventHosts.forge()
									.query('join', 'users', 'users.user_id', '=', 'event_hosts.user_id', 'inner')
									.query('where', 'event_id', '=', ev.get('event_id'))
									.fetch
										columns: ['users.*']
									.then (rsp) ->
										hosts = []
										for host in rsp.models
											h = _.pick host.attributes, ['first_name', 'last_name', 'pic', 'user_id']
											hosts.push h
										ev.set('hosts', hosts)
										evs.push ev.attributes
										cb()
							, ->
								dfr.resolve(evs)
								rds.set 'events', JSON.stringify(evs), (err, rsp) ->
									rds.expire 'events', 240
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
