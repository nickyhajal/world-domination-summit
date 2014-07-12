_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
async = require('async')
_s = require('underscore.string')

routes = (app) ->

	[RaceTask, RaceTasks] = require('../../models/racetasks')
	[RaceSubmission, RaceSubmissions] = require('../../models/race_submissions')

	racetask =
		add: (req, res, next) ->
			req.me.getCapabilities()
			.then ->
				if req.me.hasCapability('race')
					post = _.pick req.query, RaceTask::permittedAttributes
					post.slug = _s.slugify(post.task)
					post.year = process.yr
					RaceTask.forge(post)
					.save()
					.then (task) ->
						next()
					, (err) ->
						console.error(err)
				else
					res.r.msg = 'You don\'t have permission to do that!'
					res.status(403)
					next()

		upd: (req, res, next) ->
			req.me.getCapabilities()
			.then ->
				if req.me.hasCapability('race')
					post = _.pick req.query, RaceTask::permittedAttributes
					post.slug = _s.slugify(post.task)
					RaceTask.forge(post)
					.save()
					.then ->
						next()
				else
					res.r.msg = 'You don\'t have permission to do that!'
					res.status(403)
					next()

		search: (req, res, next) ->
			RaceTasks.forge()
			.query('orderBy', 'section')
			.fetch()
			.then (tasks) ->
				res.r.racetasks = tasks.models
				next()

		get_submissions: (req, res, next) ->
			RaceSubmissions.forge()
			.query('where', 'rating', '0')
			.fetch()
			.then (rsp) ->
				res.r.submissions = rsp.models
				next()

		get_all_submissions: (req, res, next) ->
			RaceSubmissions.forge()
			.query('orderBy', 'rating', 'DESC')
			.fetch()
			.then (rsp) ->
				res.r.submissions = rsp.models
				next()

module.exports = routes