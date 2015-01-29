https = require 'https'
http = require 'http'
crypto = require 'crypto'
Twit = require 'twit'
redis = require 'redis'
async = require 'async'
rds = redis.createClient()

#

[User, Users] = require('../models/users')

shell = (app, db) ->
	twit = new Twit
		consumer_key: app.settings.twitter_consumer_key
		consumer_secret: app.settings.twitter_consumer_secret
		access_token: app.settings.twitter_token
		access_token_secret: app.settings.twitter_token_secret

	Users.forge()
	.query('where', 'twitter', '<>', '')
	.query('where', 'pic', 'LIKE', '%.twimg.com%')
	.query('where', 'attending'+process.yr, '1')
	.fetch()
	.then (rsp) ->
		reqs = []
		req = []
		for user in rsp.models
			req.push user.get('twitter')
			if req.length is 100
				reqs.push req
				req = []
		async.each reqs, (req, cb) ->
			scr_name = req.join(',')
			twit.get 'users/lookup', {screen_name: scr_name}, (err, rsp) ->
				async.each rsp, (atn, atncb) ->
					User.forge
						twitter: atn.screen_name
					.fetch()
					.then (user) ->
						user.set('pic', atn.profile_image_url)
						user.save()
						tk atn.screen_name+' saved'
						atncb()
				cb()

module.exports = shell