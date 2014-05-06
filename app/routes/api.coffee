###
	Routes for the WDS API
###

routes = (app) ->

	handler = require('./api/handler')
	assets = require('./api/assets')(app)
	user = require('./api/user')(app)
	feed = require('./api/feed')(app)
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
		app.patch '/user', user.update
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
		app.get '/user', user.get
		app.get '/users', user.search
		app.get '/me', user.me

		# Feed
		app.post '/feed', feed.add
		app.put '/feed', feed.upd
		app.delete '/feed', feed.del
		app.get '/feed', feed.get
		app.post '/feed/comment', feed.add_comment
		app.get '/feed/comments', feed.get_comments

		# Ticket Transfers
		app.post '/transfer', transfer.add
		app.get '/transfer/ipn', transfer.ipn
		app.get '/transfer/return', transfer.pdt
		app.get '/transfer/status', transfer.status

		# Finish
		app.all '/*', handler.finish
module.exports = routes
