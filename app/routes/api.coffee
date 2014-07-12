###
	Routes for the WDS API
###

routes = (app) ->

	handler = require('./api/handler')

	admin= require('./api/admin')(app)
	assets = require('./api/assets')(app)
	content = require('./api/content')
	event = require('./api/event')(app)
	feed = require('./api/feed')(app)
	racetask = require('./api/racetask')(app)
	screens = require('./api/screens')(app)
	speaker = require('./api/speaker')(app)
	transfer = require('./api/transfer')(app)
	user = require('./api/user')(app)
	checkins = require('./api/checkins')(app)

	app.namespace '/api', (req, res, next)->

		# Setup
		app.all '/*', handler.start
		app.get '/assets', assets.get

		# Content
		app.get '/parse', content.parse
		app.get '/content', content.get

		# User
		app.get '/me', user.me
		app.get '/users', user.search
		app.patch '/user', user.update
		app.put '/user', user.update
		app.get '/user', user.get
		app.get '/user/ticket', user.ticket
		app.post '/user', user.create
		app.post '/user/login', user.login
		app.post '/user/reset', user.reset
		app.post '/user/registrations', user.registrations
		app.post '/user/interest', user.add_interest
		app.post '/user/connection', user.add_connection
		app.delete '/user/connection', user.del_connection
		app.delete '/user/interest', user.del_interest
		app.get '/user/twitter/connect', user.twitter_connect
		app.get '/user/twitter/callback', user.twitter_callback
		app.delete '/user/twitter', user.del_twitter
		app.post '/user/tweet', user.send_tweet
		app.post '/user/logout', user.logout
		app.post '/user/task', user.race_submission
		app.all '/user/achieved', user.achieved
		app.get '/user/racecheck', user.race_check
		app.get '/user/task', user.task
		app.get '/user/friends', user.get_friends
		app.post '/user/note', user.add_unote
		app.get '/user/notes', user.get_unotes
		app.post '/user/checkin', user.add_checkin
		app.get '/user/notifications', user.get_notifications
		app.get '/user/notifications/unread', user.get_unread_notifications
		app.get '/user/notifications/read', user.read_notifications

		# Speakers
		app.put '/speaker', speaker.update
		app.post '/speaker', speaker.create

		# Events
		app.post '/event', event.add
		app.put '/event', event.upd
		app.get '/event/attendees', event.get_attendees
		app.get '/event/hosts', event.get_hosts
		app.post '/event/rsvp', event.rsvp

		# Feed
		app.post '/feed', feed.add
		app.put '/feed', feed.upd
		app.delete '/feed', feed.del
		app.get '/feed', feed.get
		app.get '/feed/item', feed.get_item
		app.post '/feed/comment', feed.add_comment
		app.get '/feed/comments', feed.get_comments
		app.post '/feed/like', feed.add_like

		# Ticket Transfers
		app.post '/transfer', transfer.add
		app.all '/transfer/ipn', transfer.ipn
		app.get '/transfer/return', transfer.pdt
		app.get '/transfer/status', transfer.status

		# RaceTasks
		app.post '/racetask', racetask.add
		app.put '/racetask', racetask.upd
		app.get '/racetasks', racetask.search
		app.get '/racetask/submissions', racetask.get_submissions

		# Screens
		app.get '/screens', screens.get
		app.put '/screens', screens.update
		app.post '/screens/reset', screens.reset
		app.get '/screens/reset', screens.get_reset_time

		# Checkin
		app.get '/checkins', checkins.get
		app.get '/checkins/recent', checkins.get_recent

		# Admin
		# Anything in the /admin path will pull the users capabilities
		# other paths require req.query.admin to be passed as true for
		# capabilities to be grabbed automatically
		app.all '/admin/*', admin.get_capabilities
		app.get '/admin/download', admin.download
		app.get '/admin/schedule', admin.schedule
		app.get '/admin/ambassadors', admin.ambassadors
		app.get '/admin/ambassador_accept', admin.ambassador_accept
		app.get '/admin/ambassador_reject', admin.ambassador_reject
		app.get '/admin/user_export', admin.export
		app.get '/admin/locations', admin.process_locations
		app.get '/admin/events', event.get
		app.get '/admin/event_accept', event.accept
		app.get '/admin/event_reject', event.reject
		app.post '/admin/rate', admin.rate

		app.get 'tpl', (req, res, next) ->
			get_templates = require('../processors/templater')
			get_templates {}, 'pages', (tpls) ->
				get_templates tpls, '_content', (tpls) ->
					res.r.tpl = tpls['pages_'+req.query.tpl]
					next()

		# Finish
		app.all '/*', handler.finish
module.exports = routes
