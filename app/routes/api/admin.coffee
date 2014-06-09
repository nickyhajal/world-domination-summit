routes = (app) ->

	[User, Users] = require('../../models/users')

	admin =
		get_capabilities: (req, res, next) ->
			req.me.getCapabilities()
			.then (capable_me) ->
				req.me = capable_me
				next()
		export: (req, res, next) ->
			#if req.me.hasCapability('manifest')
				res.status(200)
				res.attachment 'attendees2014.csv'

				# Headers
				response = "First Name;Last Name;Email;Twitter;Type;Location\n"

				# Attendee list for 2014
				Users.forge().query('where', 'attending14', '1').fetch().then (model) -> (
					for i in [0 .. model.models.length - 1]
						attendee = model.models[i]
						response = response + attendee.get('first_name')+";"+attendee.get('last_name')+";"+attendee.get('email')+";"+attendee.get('twitter')+";"+attendee.get('type')+';"'+attendee.get('location')+'"' + "\n"
					res.send response
					res.r.msg = 'Success'
				)
			#else
			#	res.status(401)

module.exports = routes
