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

[Speaker, Speakers] = require("../models/speakers")
[Interest, Interests] = require("../models/interests")

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
		me = req.session.ident ? false
		page = 'index'
		get_templates {}, 'pages', (tpls) ->
			get_templates tpls, 'parts', (tpls) ->
				get_templates tpls, '_content', (tpls) ->
					get_templates tpls, '_sidebars', (tpls) ->
						Speakers.forge().getByType()
						.then (speakers) ->
							Interests.forge().fetch()
							.then (interests) ->
								path = req.path.substr(1)
								counter = ''

								out = {}
								this_page = 'pages_'+_s.trim(req.path, '/').replace('/', '_')
								out = _.pick(tpls, ['pages_home', 'pages_login', 'pages_404', this_page])
								for name,tpl of tpls
									if tpl.indexOf('pages_') isnt 0
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
									speakers: JSON.stringify(speakers)
									interests:  JSON.stringify(interests.models)
									me: me
									hide_counter: counter
									year: process.year
									yr: process.yr
									tpls: JSON.stringify(out)
									provinces: JSON.stringify(provinces)
									countries: JSON.stringify(countries_out)

module.exports = routes
