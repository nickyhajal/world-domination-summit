https = require 'https'
http = require 'http'
crypto = require 'crypto'
Eventbrite = require 'eventbrite'
redis = require 'redis'
rds = redis.createClient()
moment = require 'moment'
async = require 'async'

##
[Ticket, Tickets] = require '../models/tickets'
[User, Users] = require '../models/users'
[EventRsvp, EventRsvps] = require '../models/event_rsvps'

events = [
	name: 'The Art of Simple'
	event_id: '123'
	eb_id: '11350996135'
,
	name: 'Finding and Refining'
	event_id: '124'
	eb_id: '11584159533'
,
	name: 'Making and Giving'
	event_id: '125'
	eb_id: '11351507665'
,
	name: 'RevolutionU'
	event_id: '126'
	eb_id: '11557391469'
,
	name: 'Travel Hacking'
	event_id: '127'
	eb_id: '11392203387'
,
	name: 'Nerd Fitness'
	event_id: '128'
	eb_id: '11556996287'
,
	name: 'LanguageLab'
	event_id: '129'
	eb_id: '11583991029'
,
	name: 'ProBlogger'
	event_id: '130'
	eb_id: '11339594031'
,
	name: 'Portland Spirit'
	event_id: '131'
	eb_id: '11773158835'
,
	name: 'Yoga Rocks'
	event_id: '132'
	eb_id: '11967895297'
,
	name: 'Fun Run'
	event_id: '133'
	eb_id: '11776849875'
]

shell = (app) ->
	do_eb = ->
		eb = Eventbrite
			app_key: app.settings.eb_key
			user_key: app.settings.eb_user

		params = 
			id: app.settings.eb_event
			count: 10000
			page: 1

		tk 'Academy Check'

		async.each events, (ev, cb) -> 
			eb.event_list_attendees {id: ev.eb_id}, (err, data) ->
				async.each data.attendees, (atn, atncb) -> 
					User.forge
						email: atn.attendee.email
					.fetch()
					.then (user) ->
						if user
							EventRsvp.forge
								user_id: user.get('user_id')
								event_id: ev.event_id
							.fetch()
							.then (rsvp) ->
								if not rsvp
									EventRsvp.forge
										user_id: user.get('user_id')
										event_id: ev.event_id
									.save()
								atncb()
						else
							tk 
							atncb()
				, ->
					cb()
	do_eb()



module.exports = shell