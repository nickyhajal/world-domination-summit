###
# This is the main page that all is routed through
# actual routing happens by Backbone.js
###
jade = require('jade')
redis = require("redis")
rds = redis.createClient()
fs = require('fs')
_ = require('underscore')
execFile = require('child_process').execFile;
routes = (app) ->
	app.all '/git-hook', (req, res) ->
		res.render "../views/git-hook",
			layout: false
		console.log req.query
		execFile 'world-domination-summit-sync', (err, stdout, stderr) ->
			tk err


	app.get '/*', (req, res) ->
		page = 'index'
		get_templates {}, 'pages', (tpls) ->
			get_templates tpls, 'parts', (tpls) ->
				res.render "../views/#{page}",
					title: "Let's Duo!"
					env: '"'+process.env.NODE_ENV+'"'
					authd: 1
					tpls: JSON.stringify(tpls)


get_templates = (tpls, type, cb) ->
	rds.get 'tpls_'+type, (err) ->
		execFile 'find', [ __dirname + "/../views/"+type], (err, stdout, stderr) ->
			files = stdout.split '\n'
			rsp = {}

			# This will be called when all files are rendered
			finishedRendering = ->
				rds.set 'tpls', JSON.stringify(tpls), ->
					rds.expire 'tpls_'+type, 1000, ->
						cb tpls

			# This renders each file
			renderTplFile = (files, index) ->
				if files[index]?
					file = files[index]
					if (file.indexOf '.jade' ) > -1 and (file.indexOf 'index') is -1 and (file.indexOf 'response') is -1
						jade.renderFile file, {pretty: false}, (err, str) ->
							if not err
								name = _.last file.split '/'
								name = name.replace '.jade', ''
								tpls[type+'_'+name] = str
							else
								tk 'ERR IN: '+file
								tk err
								tk '-----------------'
							renderTplFile files, (index + 1)
					else
						renderTplFile files, (index + 1)
				else
					finishedRendering()
			renderTplFile files, 0
module.exports = routes
