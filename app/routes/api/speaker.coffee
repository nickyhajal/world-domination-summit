_ = require('underscore')
redis = require("redis")
async = require("async")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')

routes = (app) ->

	twitter = new twitterAPI
		consumerKey: app.settings.twitter_consumer_key
		consumerSecret: app.settings.twitter_consumer_secret
		callback: process.dmn + '/api/user/twitter/callback'

	[Speaker, Speakers] = require('../../models/speakers')

	user =
		create: (req, res, next) ->
			post = _.pick(req.query, Speaker.prototype.permittedAttributes)
			Speaker.forge(post)
			.save()
			.then (new_speaker, err) ->
				Speakers.forge().getByType()
				.then (speakers) ->
					res.r.speakers = speakers
					next()

		update: (req, res, next) ->
			if req.me
				if req.me.hasCapability('speakers')
					post = _.pick(req.query, Speaker.prototype.permittedAttributes)
					Speaker.forge(post)
					.save(null, {method: 'update'})
					.then (speaker) ->
						Speakers.forge().getByType()
						.then (speakers) ->
							res.r.speakers = speakers
							next()
					, (err) ->
						console.error(err)
			else
				res.status(401)
				next()

module.exports = routes