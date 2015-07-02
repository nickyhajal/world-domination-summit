_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
async = require('async')
_s = require('underscore.string')

routes = (app) ->

	[Place, Places] = require('../../models/places')
	[PlaceType, PlaceTypes] = require('../../models/placetypes')

	place_routes =
		add: (req, res, next) ->
			req.me.getCapabilities()
			.then ->
				if req.me.hasCapability('places') || 1
					post = _.pick req.query, Places::permittedAttributes
					post.slug = _s.slugify(post.place)
					post.year = process.yr
					Place.forge(post)
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
				if req.me.hasCapability('places') || 1
					post = _.pick req.query, Place::permittedAttributes
					Place.forge(post)
					.save()
					.then ->
						next()
				else
					res.r.msg = 'You don\'t have permission to do that!'
					res.status(403)
					next()

		get: (req, res, next) ->
			cols = {columns: ['place_types.*', 'places.*']}
			Places.forge()
			.query('orderBy', 'place_type')
			.query('join', 'place_types', 'place_types.placetypeid', '=', 'places.place_type', 'left')
			.fetch(cols)
			.then (rsp) ->
				res.r.places = rsp.models
				next()

		get_types: (req, res, next) ->
			PlaceTypes.forge()
			.fetch()
			.then (rsp) ->
				res.r.place_types = rsp.models
				next()

module.exports = routes