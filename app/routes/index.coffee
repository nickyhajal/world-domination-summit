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
[Transfer, Transfers] = require("../models/transfers")

provinces = {}
for province in all_provinces
	if not provinces[province.country]?
		provinces[province.country] = []
	provinces[province.country].push province


routes = (app) ->
	app.all '/transfers', (req, res) ->
		c = {columns: ['first_name', 'last_name', 'new_attendee']}
		transfers = Transfers.forge()
		transfers.query('where', 'year', '2015')
		transfers.query('where', 'status', 'paid')
		transfers.query('join', 'users', 'transfers.user_id', '=', 'users.user_id', 'left')
		transfers.query('orderBy', 'last_name')
		transfers.fetch(c)
		.then (rsp)->
			html = '
			<style type="text/css">
				* { font-family: arial; color:#444; font-weight:300;}
				div {padding:5px; margin-bottom:3px; background:#f4f4f4;}
				</style>'
			if req.query.from?
				html += '<h3>Transfers (To → From)</h3>'
			else
				html += '<h3>Transfers (From →	 To)</h3>'
			for t in rsp.models
				atn = JSON.parse(t.get('new_attendee'))
				if req.query.from?
					html += '<div><b>'+atn.last_name+', '+atn.first_name+' FROM '+t.get('last_name')+", "+t.get('first_name')+'</div>'
				else
					html += '<div><b>'+t.get('last_name')+', '+t.get('first_name')+' TO '+atn.last_name+', '+atn.first_name+'</div>'
			res.send(html)
	app.all '/upload-race', (req, res) ->
		rsp = false
		if req.query.rsp
			rsp = req.query.rsp
		res.render "../views/race_upload",
			title: "World Domination Summit - Avatar Upload"
			layout: false
			rsp: rsp

	app.all '/text', (req, res) ->
		res.render "../views/text",
			title: "World Domination Summit - Text Maker"
			layout: false
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

			if path.match(/[a-z0-9]{40}/)? or path is 'welcome'
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
				stripe_pk: process.env.STRIPE_PK
				tpls: JSON.stringify(out)
				provinces: JSON.stringify(provinces)
				countries: JSON.stringify(countries_out)

module.exports = routes
