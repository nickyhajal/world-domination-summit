###
# This is the main page that all is routed through
# actual routing happens by Backbone.js
###
redis = require("redis")
bodyParser = require('body-parser');

routes = (app) ->
	# app.use(bodyParser.json());
	# app.use(bodyParser.urlencoded({ extended: true }));
	app.get '/admin/registration', (req, res) ->
		me = req.session.ident ? false
		page = 'index'
		res.render "../views/registration",
			title: "World Domination Summit"
			layout: false

	app.get '/admin/kindness', (req, res) ->
		me = req.session.ident ? false
		page = 'index'
		res.render "../views/registration",
			title: "World Domination Summit"
			layout: false

module.exports = routes
