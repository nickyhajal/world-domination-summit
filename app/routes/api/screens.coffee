_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
async = require('async')
_s = require('underscore.string')
Q = require('q')


fetch_message = ->
	dfr = Q.defer()
	rds.get 'screen_message', (err, message) ->
		try
			if (message? and message and typeof JSON.parse(message) is 'object')
				dfr.resolve(JSON.parse(message))
			else
				dfr.resolve({title: "", message: "", activated: "no"})
		catch e
			console.log "Exception on retrieving screen message from redis: " + JSON.stringify(e)
			dfr.resolve({title: "", message: "", activated: "no"})
		
	return dfr.promise

routes = (app) ->
	screens =
	
		get: (req, res, next) ->
			fetch_message().then (message) ->
				res.r.message = message
				next()

		update: (req, res, next) ->
			req.me.getCapabilities().then ->
				if req.me.hasCapability('screens')
					fetch_message().then (message) ->
						if req.query.title?
							message.title = req.query.title
						if req.query.message?
							message.message = req.query.message

						if req.query.activated?
							message.activated = "no"
							if (req.query.activated == "yes")
								message.activated = "yes"
						
						rds.set 'screen_message', JSON.stringify(message), (err, rsp) ->
							if err?
								res.status(500)
							else
								res.r.message = message
							next()

				else
					res.r.msg = 'You don\'t have permission to do that!'
					res.status(403)
					next()

		reset: (req, res, next) ->
			req.me.getCapabilities().then ->
				if req.me.hasCapability('screens')
					now = new Date()
					nowUTC = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds())).getTime()
					rds.set 'screen_reload', JSON.stringify({lastResetUTC: nowUTC}), (err, rsp) ->
						if err?
							res.status(500)
						else
							res.r.lastResetUTC = {lastResetUTC: nowUTC}
						next()
				else
					res.r.msg = 'You don\'t have permission to do that!'
					res.status(403)
					next()

		get_reset_time: (req, res, next) ->
			dfr = Q.defer()
			rds.get 'screen_reload', (err, lastResetUTC) ->
				try
					if (lastResetUTC? and lastResetUTC and typeof JSON.parse(lastResetUTC) is 'object')
						dfr.resolve(JSON.parse(lastResetUTC))
					else
						dfr.resolve({lastResetUTC: 0})
				catch e
					console.log "Exception on retrieving last screen reset time from redis: " + JSON.stringify(e)
					dfr.resolve({lastResetUTC: 0})

			dfr.promise.then (lastResetUTC) ->
				res.r.lastResetUTC = lastResetUTC
				next()

module.exports = routes
