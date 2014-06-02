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
		app.post '/user/interest', user.add_interest
		app.post '/user/connection', user.add_connection
		app.delete '/user/connection', user.del_connection
		app.delete '/user/interest', user.del_interest
		app.get '/user/twitter/connect', user.twitter_connect
		app.get '/user/twitter/callback', user.twitter_callback
		app.delete '/user/twitter', user.del_twitter
		app.post '/user/tweet', user.send_tweet

		app.put '/speaker', speaker.update
		app.post '/speaker', speaker.create

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

		app.get '/admin/download', (req, res, next) ->
			if req.me?
				req.me.getCapabilities()
				.then ->
					if req.me?.hasCapability('downloads')
						res.attachment(req.query.file);
						res.sendfile(req.query.file, {root: '/var/www/secure_files/'});
					else
						res.r.msg = 'Not authorized'
						next()
			else
				res.r.msg = 'Not logged in'
				next()

		# Admin
		# Anything in the /admin path will pull the users capabilities
		# other paths require req.query.admin to be passed as true for
		# capabilities to be grabbed automatically
		app.all '/admin/*', admin.get_capabilities
		app.get '/admin/user_export', admin.export


		# Finish
		app.all '/*', handler.finish
module.exports = routes
