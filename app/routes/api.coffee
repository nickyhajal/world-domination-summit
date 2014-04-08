###
# Routes for the WDS API
###
handler = require('./api/handler')
user = require('./api/user')
content = require('./api/content')

routes = (app) ->
	app.namespace '/api', (req, res, next)->

		# Setup
		app.all '/*', handler.start

		# Content
		app.get '/parse', content.parse
		app.get '/content', content.get

		# User
		app.post '/user', user.update
		app.post '/user/login', user.login
		app.get '/me', user.me
		app.get '/user', user.get

		# Finish
		app.all '/*', handler.finish
module.exports = routes
