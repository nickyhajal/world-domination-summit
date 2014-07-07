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

module.exports = routes
