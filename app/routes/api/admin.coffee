async = require 'async'
_s = require('underscore.string')
routes = (app) ->
	[User, Users] = require('../../models/users')
	[Event, Events] = require('../../models/events')
	[EventHost, EventHosts] = require('../../models/event_hosts')
	[RaceSubmission, RaceSubmissions] = require('../../models/race_submissions')
	[Achievement, Achievements] = require('../../models/achievements')
	[Transfer, Transfers] = require('../../models/transfers')
	admin =
		get_capabilities: (req, res, next) ->
			req.me.getCapabilities()
			.then (capable_me) ->
				req.me = capable_me
				next()
		process_attendees: (req, res, next) ->
			Users.forge()
			.query('where', 'attending'+process.yr, '=', '1')
			.fetch()
			.then (rsp) ->
				async.each rsp.models, (user, cb) ->
					first_name = _s.titleize(user.get('first_name'))
					last_name = _s.titleize(user.get('last_name'))
					location = user.getLocationString()
					type = user.get('type')+''
					if type.length < 1 || type == 'null' || type == null
						type = 'attendee'
					user.set
						first_name: first_name
						last_name: last_name
						location: location
						type: type
					user.save()
					cb()
				, ->
					next()

		kind: (req, res, next) ->
			if req.query.user_id? and req.query.kinded?
				User.forge
					user_id: req.query.user_id
					kinded: req.query.kinded
				.save()
				.then (user) ->
					next()
			else
				next()

		process_locations: (req, res, next) ->
			Users.forge()
			.query('where', 'attending'+process.yr, '=', '1')
			.query('where', 'distance', '=', '0')
			.fetch()
			.then (rsp) ->
				count = 0
				async.eachSeries rsp.models, (user, cb) ->
					user.processAddress()
					count += 1
					setTimeout ->
						if count < 100
							cb()
						else
							tk 'FINISH FROM COUNT'
							cb('Stop')
					, 250
				, ->
					tk 'FINISH'
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
				RaceSubmission.forge
					submission_id: submission_id
				.fetch()
				.then (sub) ->
					tk sub.sendRatingEmail
					sub.sendRatingEmail(rating)
				if rating is -1
					Achievement.forge
						ach_id: ach_id
						add_points: '-1'
					.save()
				else if rating is 2 or rating is 3
					bonus = rating
					if bonus is 2
						bonus = 1
					Achievement.forge
						ach_id: ach_id
						add_points: bonus
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

		transfer_export: (req, res, next) ->
			if req.me.hasCapability('manifest')
				res.status(200)
				res.attachment 'transfers-'+process.year+'.csv'
				ts = []

				# Headers
				response = "sep=;\n"
				response += "From Name;To Name;To Email\n"

				# Attendee list for current year
				columns = {columns: ['transfer_id', 'new_attendee', 'users.user_id', 'first_name', 'last_name', 'user_name', 'pic', 'transfers.created_at', 'to_id']}
				Transfers.forge()
				.query (qb) ->
					qb.where('year', process.year)
					qb.where('status', 'paid')
					qb.orderBy('transfer_id')
					qb.join('users', 'users.user_id', '=', 'transfers.user_id')
				.fetch(columns)
				.then (rsp) ->
					for t in rsp.models
						n = JSON.parse(t.get('new_attendee'))
						response += t.get('first_name')+' '+t.get('last_name')+';'
						response += n.first_name+' '+n.last_name+';'
						response += n.email+';'
						response += "\n"
					res.send response
					res.r.msg = 'Success'
			else
				res.status(401)

		export: (req, res, next) ->
			if req.me.hasCapability('manifest')
				res.status(200)
				res.attachment 'attendees'+process.year+'.csv'

				# Headers
				response = "sep=;"
				response += "First Name;Last Name;Email;Twitter;Type;Location;Address;City;State/Region;Country;Zip\n"

				# Attendee list for current year
				Users.forge()
				.query('where', 'attending'+process.yr, '1')
				.fetch().then (model) ->
					for attendee in model.models
						response = response + attendee.get('first_name')+";"+attendee.get('last_name')+";"+attendee.get('email')+";"+attendee.get('twitter')+";"+attendee.get('type')+';"'+attendee.get('location')+'";"'+attendee.get('address')+'";"'+attendee.get('city')+'";"'+attendee.get('region')+'";"'+attendee.get('country')+'";"'+attendee.get('zip')+'"'+"\n"
					res.send response
					res.r.msg = 'Success'
			else
				res.status(401)


		export_profile_stat: (req, res, next) ->
			if req.me.hasCapability('manifest')
				res.status(200)
				res.attachment 'attendee_profiles-'+process.year+'.csv'

				# Headers
				rsp = "sep=;"
				rsp += "First Name;Last Name;Email;Profile Step;Has Username;Has Address;Has Pic;\n"

				# Attendee list for current year
				Users.forge()
				.query('where', 'attending'+process.yr, '1')
				.fetch().then (model) ->
					for a in model.models
						profileStep = a.get('intro')
						hasAddress = a.get('address')?.length > 0 || a.get('region')?.length > 0
						hasUsername = a.get('user_name').length < 40
						hasPic = a.get('pic').length > 0
						if profileStep < 10 || !hasAddress || !hasUsername || !hasPic
							rsp += a.get('first_name')+";"+a.get('last_name')+";"
							rsp += a.get('intro')+";"
							if hasAddress
								rsp += "Y;"
							else
								rsp += "N;"
							if hasUsername
								rsp += "Y;"
							else
								rsp += "N;"
							if hasPic
								rsp += "Y;"
							else
								rsp += "N;"
							rsp += "\n"
					res.send rsp
					res.r.msg = 'Success'
			else
				res.status(401)

		schedule: (req, res, next) ->
			Events.forge()
			.query('whereIn', 'type', ['program', 'spark_session', 'activity'])
			.query('where', 'year', process.yr)
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

		transfers: (req, res, next) ->
			columns = {columns: ['transfer_id', 'new_attendee', 'users.user_id', 'first_name', 'last_name', 'user_name', 'pic', 'transfers.created_at', 'to_id']}
			Transfers.forge()
			.query (qb) ->
				qb.where('year', process.year)
				qb.where('status', 'paid')
				qb.orderBy('transfer_id')
				qb.join('users', 'users.user_id', '=', 'transfers.user_id')
			.fetch(columns)
			.then (rsp) ->
				ts = []
				async.eachSeries rsp.models, (t, cb) ->
					if t.get('to_id') > 0
						ts.push t
						cb()
					else
						atn = JSON.parse(t.get('new_attendee'))
						User.forge
							email: atn.email
						.fetch()
						.then (existing) ->
							if existing
								user_id = existing.get('user_id')
								ts.push t
								cb()
								Transfer.forge
									transfer_id: t.get('transfer_id')
									to_id: user_id
								.save()
								.then (tx) ->
									tk 'saved'
							else
								ts.push t
								cb()
				, ->
					res.r.transfers = ts
					next()

		academies: (req, res, next) ->
			Events.forge()
			.query('where', 'type', 'academy')
			.query('where', 'year', process.yr)
			.query('orderBy', 'start')
			.fetch()
			.then (events) ->
				evs = []
				async.eachSeries events.models, (ev, cb) ->
					tmp = ev.attributes
					EventHosts.forge()
					.query('where', 'event_id', tmp.event_id)
					.fetch()
					.then (hs) ->
						host_ids = []
						for h in hs.models
							host_ids.push h.get('user_id')
						start = (tmp.start+'').split(' GMT')
						start = moment(start[0])
						tmp.start = start.format('YYYY-MM-DD HH:mm:ss')
						tmp.host_ids = host_ids
						evs.push(tmp)
						cb()

				, ->
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
					model.set('attending'+process.yr, 1)
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
