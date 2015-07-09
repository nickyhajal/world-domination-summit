_ = require('underscore')
redis = require("redis")
rds = redis.createClient()
twitterAPI = require('node-twitter-api')
moment = require('moment')
crypto = require('crypto')
async = require('async')
pdf = require('html-pdf');
_s = require('underscore.string')
fs = require 'fs'
routes = (app) ->

	[Event, Events] = require('../../models/events')
	[EventHost, EventHosts] = require('../../models/event_hosts')
	[EventRsvp, EventRsvps] = require('../../models/event_rsvps')
	[EventInterest, EventInterests] = require('../../models/event_interests')
	[User, Users] = require('../../models/users')

	event =
		add: (req, res, next) ->
			if req.me
				post = _.pick req.query, Event::permittedAttributes
				start = moment.utc(process.year+'-07-'+req.query.date+' '+req.query.hour+':'+req.query.minute+':00', 'YYYY-MM-DD HH:mm:ss')
				if req.query.hour is '12'
					req.query.pm = Math.abs(req.query.pm - 12)
				post.start = start.add('hours', req.query.pm).format('YYYY-MM-DD HH:mm:ss')

				if not post.type?
					post.type = 'meetup'

				post.year = process.yr

				Event.forge(post)
				.save()
				.then (event) ->
					if post.type is 'meetup'
						EventHost.forge({event_id: event.get('event_id'), user_id: req.me.get('user_id')})
						.save()
						.then (host) ->
							if req.query.interests? and req.query.interests.length
								async.each req.query.interests.split(','), (interest, cb) ->
									EventInterest.forge({event_id: event.get('event_id'), interest_id: interest})
									.save()
									.then (interest) ->
										cb()
								, ->
									next()
							else
								next()
						, (err) ->
							console.error(err)
					else
						next()
				, (err) ->
					console.error(err)
			else
				res.r.msg = 'You\'re not logged in!'
				res.status(401)
				next()

		upd: (req, res, next) ->
			if req.me
				post = _.pick req.query, Event::permittedAttributes
				start = moment.utc(process.year+'-07-'+req.query.date+' '+req.query.hour+':'+req.query.minute+':00', 'YYYY-MM-DD HH:mm:ss')
				if req.query.hour is '12'
					req.query.pm = Math.abs(req.query.pm - 12)
				post.start = start.add('hours', req.query.pm).format('YYYY-MM-DD HH:mm:ss')
				Event.forge({event_id: post.event_id})
				.fetch()
				.then (ev) ->
					EventHost.forge({event_id: post.event_id, user_id: req.me.get('user_id')})
					.fetch()
					.then (host) ->
						if not host
							req.me.getCapabilities()
							.then ->
								if req.me.hasCapability('schedule')
									ev.set(post)
									.save()
									.then ->
										next()
								else
									res.r.msg = 'You don\'t have permission to do that!'
									res.status(403)
									next()
						else
								ev.set(post)
								.save()
								.then ->
									next()
			else
				res.r.msg = 'You don\'t have permission to do that!'
				res.status(403)
				next()

		del: (req, res, next) ->
			if req.me? && req.me.hasCapability('schedule')
				if req.query.feed_id?
					Feed.forge req.query.feed_id
					.fetch()
					.then (feed) ->
						if feed.get('user_id') is req.me.get('user_id')
							feed.destroy()
							.then ->
								next()
				else
					res.r.msg = 'No feed item sent'
					res.status(400)
					next()
			else
				res.status(401)
				next()

		get_admin: (req, res, next) ->
			events = Events.forge()
			limit = req.query.per_page ? 500
			page = req.query.page ? 1
			events.query('where', 'year', process.yr)
			if req.query.active?
				active = req.query.active
				events.query('where', 'active', active)
			if req.query.type?
				events.query('where', 'type', req.query.type)
			if req.query.event_id
				events.query('where', 'event_id', req.query.event_id)
			events.query('orderBy', 'event_id',  'DESC')
			events.query('limit', limit)
			events.query('where', 'ignored', 0)
			events
			.fetch()
			.then (events) ->
				evs = []
				async.each events.models, (ev, cb) ->
					tmp = ev.attributes
					tmp.hosts = []
					start = (tmp.start+'').split(' GMT')
					start = moment(start[0])
					tmp.start = start.format('YYYY-MM-DD HH:mm:ss')
					columns = {columns: ['users.user_id', 'first_name', 'last_name', 'attending15']}
					EventHosts.forge()
					.query('where', 'event_id', '=', tmp.event_id)
					.query('join', 'users', 'event_hosts.user_id', '=', 'users.user_id', 'inner')
					.fetch(columns)
					.then (rsp) ->
						for host in rsp.models
							tmp.hosts.push(host)
						evs.push(tmp)
						cb()
					, (err) ->
						console.error err
				, ->
					res.r.events = evs
					next()

		get: (req, res, next) ->
			events = Events.forge()
			if req.query.event_id
				events.query('where', 'event_id', req.query.event_id)
			events
			.fetch()
			.then (events) ->
				out = false

				async.each events.models, (ev, cb) ->
					tmp = ev.attributes
					tmp.hosts = []
					tmp.atns = []
					start = (tmp.start+'').split(' GMT')
					start = moment(start[0])
					tmp.start = start.format('YYYY-MM-DD HH:mm:ss')
					tmp.startStr = moment(tmp.start).format('h:mm a')
					tmp.dayStr = moment(tmp.start).format('dddd[,] MMMM Do')
					tmp.startDay = moment(tmp.start).format('YYYY-MM-DD')
					EventHosts.forge()
					.query('join', 'users', 'users.user_id', '=', 'event_hosts.user_id', 'inner')
					.query('where', 'event_id', '=', tmp.event_id)
					.fetch
						columns: ['users.*']
					.then (rsp) ->
						for host in rsp.models
							h = _.pick host.attributes, User::limitedAttributes
							tmp.hosts.push(h)
						EventRsvps.forge()
						.query('join', 'users', 'event_rsvps.user_id', '=', 'users.user_id', 'inner')
						.query('where', 'event_id', '=', tmp.event_id)
						.fetch
							columns: ['users.*']
						.then (rsp) ->
							tk 'RSVP DN'
							for atn in rsp.models
								atn = _.pick atn.attributes, User::limitedAttributes
								tmp.atns.push(atn)
							out = tmp
							cb()
				, ->
					res.r.event = out
					next()

		accept: (req, res, next) ->
			if req.me.hasCapability('schedule')
				Event.forge
					event_id: req.query.event_id
				.fetch()
				.then (model) ->
					EventHost.forge({event_id: req.query.event_id})
					.fetch()
					.then (host) ->
						User.forge({user_id: host.get('user_id')})
						.fetch()
						.then (host) ->
							host.sendEmail('meetup-approved', 'Thanks for your meetup proposal!')
							model.set('active', 1)
							model.save()
							next()
			else
				res.status(401)
				next()

		reject: (req, res, next) ->
			if req.me.hasCapability('schedule')
				Event.forge
					event_id: req.query.event_id
				.fetch()
				.then (model) ->
					EventHost.forge({event_id: req.query.event_id})
					.fetch()
					.then (host) ->
						User.forge({user_id: host.get('user_id')})
						.fetch()
						.then (host) ->
		#					host.sendEmail('meetup-declined', 'Thanks for your meetup proposal!')
							model.set('ignored', 1)
							model.save()
							next()
				, (err) ->
					console.error(err)
			else
				res.status(401)
				next()

		get_attendees: (req, res, next) ->
			event_id = req.query.event_id
			sig = 'event_atns_'+event_id+'_'+req.query.include_users?
			rds.get sig, (err, atns) ->
				if atns? and atns and typeof JSON.parse(atns) is 'object'
					res.r.attendees = JSON.parse(atns)
					next()
				else
					columns = {columns: ['users.user_id', 'first_name', 'last_name', 'pic']}
					EventRsvps.forge()
					.query('where', 'event_id', '=', event_id)
					.query('join', 'users', 'event_rsvps.user_id', '=', 'users.user_id', 'inner')
					.fetch(columns)
					.then (rsp) ->
						atns = []
						for atn in rsp.models
							if req.query.include_users?
								atns.push(atn)
							else
								atns.push(atn.get('user_id'))
						res.r.attendees = atns
						rds.set sig, JSON.stringify(atns), ->
						rds.expire sig, 45
						next()
					, (err) ->
						console.err(err)


		rsvp: (req, res, next) ->
			event_id = req.query.event_id
			if req.me
				rsvp = EventRsvp.forge({user_id: req.me.get('user_id'), event_id: event_id})
				rsvp
				.fetch()
				.then (existing) ->
					if existing
						res.r.action = 'cancel'
						existing.destroy()
						.then ->
							finish()
					else
						res.r.action = 'rsvp'
						rsvp.save()
						.then ->
							finish()

					finish = ->
						EventRsvps.forge()
						.query('where', 'event_id', event_id)
						.fetch()
						.then (rsp) ->
							Event.forge
								event_id: event_id
								num_rsvps: rsp.models.length
							.save()
						next()

		get_pdf: (req, res, next) ->
			from = process.year+"-07-"+req.query.from_date+" "
			from_hour = req.query.from_hour
			if req.query.from_pm == '12'
				if req.query.from_hour != '12'
					from_hour = parseInt(from_hour) + 12
			else if req.query.from_hour == '12'
				from_hour = '0'
			if (''+from_hour).length == 1
				from_hour = '0'+from_hour
			from += from_hour+":"+req.query.from_minute+":00"
			to = process.year+"-07-"+req.query.to_date+" "
			to_hour = req.query.to_hour
			if req.query.to_pm == '12'
				if req.query.to_hour != '12'
					+to_hour += 12
			else if req.query.to_hour == '12'
				to_hour = '0'
			if (''+to_hour).length == 1
				to_hour = '0'+to_hour
			to += to_hour+":"+req.query.to_minute+":00"
			_e = Events.forge()
			events = Events.forge()
			events.query('where', 'year', process.yr)
			if req.query.include_full? && req.query.include_full == '0'
				events.query('whereRaw', 'events.num_rsvps < events.max')
			events.query('where', 'active', '1')
			events.query('where', 'type', 'meetup')
			events.query('where', 'start', '>=', from)
			events.query('where', 'start', '<=', to)
			events.query('orderBy', 'start')
			events
			.fetch()
			.then (events) ->
				html = '<style type="text/css">
				@font-face {font-family: "Vitesse"; src: url("file:///var/www/world-domination-summit/fonts/Vitesse-Medium.otf") format("opentype");}
				@font-face {font-family: "VitesseLight"; src: url("file:///var/www/world-domination-summit/fonts/Vitesse-Light.otf") format("opentype");}
				@font-face {font-family: "VitesseBold"; src: url("file:///var/www/world-domination-summit/fonts/Vitesse-Bold.otf") format("opentype");}
				@font-face {font-family: "VitesseBook"; src: url("file:///var/www/world-domination-summit/fonts/Vitesse-Book.otf") format("opentype");}
				@font-face {font-family: "Populaire"; src: url("file:///var/www/world-domination-summit/fonts/Populaire.otf") format("opentype");}
				@font-face {font-family: "Karla"; src: url("file:///var/www/world-domination-summit/fonts/Karla-Regular.ttf") format("truetype");}
				@font-face {font-family: "KarlaBold"; src: url("file:///var/www/world-domination-summit/fonts/Karla-Bold.ttf") format("truetype");}
				@font-face {font-family: "KarlaItalic"; src: url("file:///var/www/world-domination-summit/fonts/Karla-Italic.ttf") format("truetype");}
					.meetup {
						background: #FCFCFA;
						padding: 20px;
						font-family:"Karla";
						margin-bottom:10px;
						color: #21170A;
					}
					h1 {
						color: #0A72B0;
						font-family: "Vitesse";
					}
					h5 {
						color: #0A72B0;
						font-family: "Karla";
						font-size:18pt;
						margin:10px 0 4px;
					}
					h4 {
						margin: 3px 0 6px;
						font-weight: bold;
						font-size:14pt;
						color: #848477;
					}
					h3, .descr {
						font-family:"Karla";
					}
					h2 {
						margin: 0;
					}
				</style>'
				lastDay = ''
				lastStart = ''
				for ev in events.models
					startStr = moment(ev.get('start')).format('h:mm a')
					dayStr = moment(ev.get('start')).format('dddd[,] MMMM Do')
					if dayStr != lastDay
						lastDay = dayStr
						html += '<h1>'+dayStr+'</h1>'
					if lastStart != startStr
						lastStart = startStr
						html += '<h5>'+startStr+'</h5>'
					html += '<div class="meetup"><h2 style="font-family:Vitesse">'+ev.get('what')+'</h2>'
					html += '<h4>'+ev.get('place')+' - '+ev.get('address')+'</h4>'
					html += '<h3>A meetup for '+_s.decapitalize(ev.get('who'))+'</h3>'
					html += '<div class="descr">'+ev.get('descr').replace(RegExp("\n","g"), "<br>")+'</div></div>'
				options =
					format: 'Letter'
					border: '.4in'
				pdf.create(html, options).toFile './meetups-printable.pdf', (err, rsp) ->
					if err
						console.error err
					else
						next()


module.exports = routes
