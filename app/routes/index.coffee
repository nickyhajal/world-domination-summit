###
# This is the main page that all is routed through
# actual routing happens by Backbone.js
###
redis = require("redis")
all_provinces = require('provinces')
countries = require('country-data').countries
get_templates = require('../processors/templater')
_ = require('underscore')
_s = require('underscore.string')

#

[User, Users] = require("../models/users")

provinces = {}
for province in all_provinces
	if not provinces[province.country]?
		provinces[province.country] = []
	provinces[province.country].push province


routes = (app) ->
	app.all '/upload-avatar', (req, res) ->
		res.render "../views/upload",
			title: "World Domination Summit - Avatar Upload"
			layout: false
	app.get '/*', (req, res) ->

		me = if req.session.ident? then JSON.parse(req.session.ident) else {user_id: 0}
		page = 'index'
		templates = {}

		get_templates {}, 'pages', (tpls) ->
			get_templates tpls, 'parts', (tpls) ->
				get_templates tpls, '_content', (tpls) ->
					get_templates tpls, '_sidebars', (tpls) ->
						templates = tpls
						User.forge({user_id: me.user_id})
						.fetch()
						.then (user) ->
							if user
								user.getMe()
								.then (user) ->
									me = JSON.stringify(user)
									finishRender()
							else
								me = false
								finishRender()

		finishRender = ->
			path = req.path.substr(1)
			counter = ''
			out = {}
			this_page = 'pages_'+_s.trim(req.path, '/').replace('/', '_')
			out = _.pick(templates, ['pages_home', 'pages_login', 'pages_404', 'pages_profile', 'pages_meetup', 'pages_dispatch', 'pages_welcome', 'pages_hub', 'pages_settings', 'pages_empty', 'pages_community', this_page])
			for name,tpl of templates
				if name.indexOf('pages_') isnt 0
					out[name] = tpl

			if path.length is 40 or path is 'welcome'
				counter = 'hide-counter'
			countries_out = {all: []}
			for country in countries.all
				countries_out.all.push
					alpha2: country.alpha2
					name: country.name
			res.render "../views/#{page}",
				title: "World Domination Summit"
				env: '"'+process.env.NODE_ENV+'"'
				me: me
				hide_counter: counter
				year: process.year
				yr: process.yr
				tpls: JSON.stringify(out)
				provinces: JSON.stringify(provinces)
				countries: JSON.stringify(countries_out)

module.exports = routes
