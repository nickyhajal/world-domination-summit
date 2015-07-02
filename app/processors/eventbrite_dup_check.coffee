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
			by_email = {}
			dup_count = 0
			simple_atn = (atn) ->
				return {first_name: atn.first_name, last_name: atn.last_name, email: atn.email}
			processAttendees = (attendees, inx = 0) ->
				if attendees[inx]?
					attendee = attendees[inx].attendee
					email = attendee.email
					if by_email[email]?
						by_email[email].push(simple_atn(attendee))
						dup_count += 1
					else
						by_email[email] = [simple_atn(attendee)]
					processAttendees(attendees, inx+1)
				else
					for email,atns of by_email
						if atns.length > 1
							tk '=========================================================='
							for atn in atns
								tk atn.first_name+', '+atn.last_name+', '+atn.email
					tk dup_count
			processAttendees(data.attendees)
	do_eb()



module.exports = shell