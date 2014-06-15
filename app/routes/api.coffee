###
	Routes for the WDS API
###

routes = (app) ->

	handler = require('./api/handler')
	assets = require('./api/assets')(app)
	user = require('./api/user')(app)
	feed = require('./api/feed')(app)
	speaker = require('./api/speaker')(app)
	admin= require('./api/admin')(app)
	transfer = require('./api/transfer')(app)
	content = require('./api/content')
	event = require('./api/event')(app)

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

		# Speakers
		app.put '/speaker', speaker.update
		app.post '/speaker', speaker.create

		# Events
		app.post '/event', event.add
		app.put '/event', event.upd

		# Feed
		app.post '/feed', feed.add
		app.put '/feed', feed.upd
		app.delete '/feed', feed.del
		app.get '/feed', feed.get
		app.post '/feed/comment', feed.add_comment
		app.get '/feed/comments', feed.get_comments

		# Ticket Transfers
		app.post '/transfer', transfer.add
		app.all '/transfer/ipn', transfer.ipn
		app.get '/transfer/return', transfer.pdt
		app.get '/transfer/status', transfer.status


		# Admin
		# Anything in the /admin path will pull the users capabilities
		# other paths require req.query.admin to be passed as true for
		# capabilities to be grabbed automatically
		app.all '/admin/*', admin.get_capabilities
		app.get '/admin/download', admin.download
		app.get '/admin/ambassadors', admin.ambassadors
		app.get '/admin/ambassador_accept', admin.ambassador_accept
		app.get '/admin/ambassador_reject', admin.ambassador_reject
		app.get '/admin/user_export', admin.export
		app.get '/admin/locations', admin.process_locations


		# Finish
		app.all '/*', handler.finish
module.exports = routes
