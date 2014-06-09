async = require 'async'
routes = (app) ->

	[User, Users] = require('../../models/users')

	admin =
		get_capabilities: (req, res, next) ->
			req.me.getCapabilities()
			.then (capable_me) ->
				req.me = capable_me
				next()
		process_locations: (req, res, next) ->
			Users.forge()
			.query('where', 'attending14', '=', '1')
			.query('where', 'location', '=', '')
			.fetch()
			.then (rsp) ->
				async.each rsp.models, (user, cb) ->
					loc = user.getLocationString()
					user.set({location: loc}).save().then ->
						cb()
				, ->
					next()


		download: (req, res, next) ->
			if req.me?
				if req.me?.hasCapability('downloads')
					res.attachment(req.query.file);
					res.sendfile(req.query.file, {root: '/var/www/secure_files/'});
				else
					res.r.msg = 'Not authorized'
					next()
			else
				res.r.msg = 'Not logged in'
				next()
		export: (req, res, next) ->
			if req.me.hasCapability('manifest')
				res.status(200)
				res.attachment 'attendees2014.csv'

				# Headers
				response = "First Name;Last Name;Email;Twitter;Type;Location;City;State/Region;Country\n"

				# Attendee list for 2014
				Users.forge().query('where', 'attending14', '1').fetch().then (model) ->
					for i in model.models
						attendee = model.models[i]
						response = response + attendee.get('first_name')+";"+attendee.get('last_name')+";"+attendee.get('email')+";"+attendee.get('twitter')+";"+attendee.get('type')+';"'+attendee.get('location')+'";'+attendee.get('city')+';'+attendee.get('region')+';'+attendee.get('country')+"\n"
					res.send response
					res.r.msg = 'Success'
			else
				res.status(401)
				next()

module.exports = routes
