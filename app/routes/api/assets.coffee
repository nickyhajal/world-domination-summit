_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
Q = require('q')
async = require('async')


# We clear some items in our redis cache upon start-up
clearCache = ->
	clear = (key) ->
		rds.expire key, 0
	clear('tpls_pages')
	clear('tpls_parts')
	clear('tpls__content')
	clear('tpls__sidebars')

clearCache()

routes = (app) ->

	[User, Users] = require('../../models/users')

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
										dfr.resolve(user)
				else
					dfr.resolve(false)
				return dfr.promise




module.exports = routes