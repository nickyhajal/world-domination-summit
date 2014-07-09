async = require 'async'
routes = (app) ->

	[User, Users] = require('../../models/users')
	[Event, Events] = require('../../models/events')
	[RaceSubmission, RaceSubmissions] = require('../../models/race_submissions')
	[Achievement, Achievements] = require('../../models/achievements')

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
					
		rate: (req, res, next) ->
			submission_id = req.query.submission_id
			rating = +req.query.rating
			ach_id = req.query.ach_id
			RaceSubmission.forge
				submission_id: submission_id
				rating: rating
			.save()
			.then (rsp) ->
				if rating is -1
					Achievement.forge
						ach_id: ach_id
						add_points: '-1'
					.save()
				else if rating is 2 or rating is 3
					Achievement.forge
						ach_id: ach_id
						add_points: rating
					.save()
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
				Users.forge()
				.query('where', 'attending14', '1')
				.query('where', 'user_id', '>', '6248')
				.fetch().then (model) ->
					for attendee in model.models
						response = response + attendee.get('first_name')+";"+attendee.get('last_name')+";"+attendee.get('email')+";"+attendee.get('twitter')+";"+attendee.get('type')+';"'+attendee.get('location')+'";'+attendee.get('city')+';'+attendee.get('region')+';'+attendee.get('country')+"\n"
					res.send response
					res.r.msg = 'Success'
			else
				res.status(401)

		schedule: (req, res, next) ->
			Events.forge()
			.query('where', 'type', 'program')
			.query('orderBy', 'start')
			.fetch()
			.then (events) ->
				evs = []
				for ev in events.models
					tmp = ev.attributes
					start = (tmp.start+'').split(' GMT')
					start = moment(start[0])
					tmp.start = start.format('YYYY-MM-DD HH:mm:ss')
					evs.push(tmp)
				res.r.events = evs
				next()

		ambassadors: (req, res, next) ->
			Users.forge()
				.query('where', 'type', 'potential-ambassador')
				.fetch()
				.then (model) ->
					res.r.users = model
					next()
		ambassador_accept: (req, res, next) ->
			if req.me.hasCapability('ambassadors')
				User.forge
					user_id: req.query.user_id
				.fetch()
				.then (model) ->
					model.set('type', 'ambassador')
					model.set('attending14', 1)
					model.save()
					res.redirect('/admin/ambassadors')
			else
				res.status(401)
				next()
		ambassador_reject: (req, res, next) ->
			if req.me.hasCapability('ambassadors')
				User.forge
					user_id: req.query.user_id
				.fetch()
				.then (model) ->
					model.set('type', 'rejected-ambassador')
					model.save()
					res.redirect('/admin/ambassadors')
			else
				res.status(401)
				next()

module.exports = routes
