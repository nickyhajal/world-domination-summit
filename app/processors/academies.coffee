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
	name: 'Fuel Your Passion'
	event_id: '272'
	eb_id: '16185910494'
,
	name: 'Hack Your World with Tarot'
	event_id: '273'
	eb_id: '16193227379'
,
	name: 'How to Become a Location Rebel'
	event_id: '274'
	eb_id: '16259605919'
,
	name: 'Language Lab'
	event_id: '275'
	eb_id: '16189146172'
,
	name: 'The Art of Becoming Known'
	event_id: '276'
	eb_id: '16259627985'
,
	name: 'Rejection Academy'
	event_id: '277'
	eb_id: '16845247589'
,
	name: 'How To Take Action After WDS'
	event_id: '278'
	eb_id: '16503325892'
,
	name: 'People Skills for Business'
	event_id: '279'
	eb_id: '16607078218'
,
	name: 'Journaling for an Enhanced Life'
	event_id: '280'
	eb_id: '16869900326'
,
	name: 'Microhousing 101'
	event_id: '281'
	eb_id: '16193369805'
,
	name: 'How to Get Your Book Published'
	event_id: '282'
	eb_id: '16192588468'
,
	name: '5K Fun Run'
	event_id: '283'
	eb_id: '17529885359'
,
	name: 'River Cruise on the Portland Spirit'
	event_id: '284'
	eb_id: '17177630756'
,
	name: 'Sunset Yoga in the Square'
	event_id: '285'
	eb_id: '17407134207'
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

		async.eachSeries events, (ev, cb) ->
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
							User.forge
								first_name: atn.attendee.first_name
								last_name: atn.attendee.last_name
							.set('attending'+process.yr, '1')
							.fetch()
							.then (user) ->
								if user
									EventRsvp.forge
										user_id: user.get('user_id')
										event_id: ev.event_id
									.fetch()
									.then (rsvp) ->
										if not rsvp
											tk 'CREATE RSVP'
											EventRsvp.forge
												user_id: user.get('user_id')
												event_id: ev.event_id
											.save()
										atncb()
								else
									atncb()

							atncb()
				, ->
					cb()
	do_eb()



module.exports = shell