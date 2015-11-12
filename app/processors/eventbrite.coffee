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

shell = (app) ->
	do_eb = ->
		eb = Eventbrite
			app_key: app.settings.eb_key
			user_key: app.settings.eb_user

		params =
			id: app.settings.eb_event
			count: 10000
			page: 1

		tk 'Start EB...'

		eb.event_list_attendees id: app.settings.eb_event, (err, data) ->
			processAttendees = (attendees, inx = 0) ->
				if attendees[inx]?
					attendee = attendees[inx].attendee
					inx += 1 # For the next attendee
					eventbrite_id = attendee.barcode
					ticket = Ticket.forge({eventbrite_id: eventbrite_id}).fetch()
					.then (ticket) ->

						# The ticket exists, skip it
						if ticket || attendee.created < "2015-11-08 00:00:00"
							processAttendees attendees, inx

						# The ticket doesn't exist, process it
						else
							User.forge({email: attendee.email}).fetch()
							.then (user) ->

								# User exists, we just need to give them the ticket
								if user
									user.registerTicket(attendee.barcode, 'returning')
									processAttendees attendees, inx

								# User doesn't exist, create and give ticket
								else
									user = User.forge
										email: attendee.email
										first_name: attendee.first_name
										last_name: attendee.last_name
										address: attendee.home_address
										address2: attendee.home_address_2
										city: attendee.home_city
										region: attendee.home_region
										zip: attendee.home_postal_code
										country: attendee.home_country_code
									user.set('attending'+process.yr, '1')
									user
									.save()
									.then (new_user, err) ->
										new_user.registerTicket(attendee.barcode)
										processAttendees attendees, inx
									, (err) ->
										console.error(err)
				else
					setTimeout ->
						do_eb()
					, 120000
			processAttendees(data.attendees)
	do_eb()



module.exports = shell