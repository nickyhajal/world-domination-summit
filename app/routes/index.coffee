###
# This is the main page that all is routed through
# actual routing happens by Backbone.js
###
jade = require('jade')
redis = require("redis")
[Speaker, Speakers] = require("../models/speakers")
rds = redis.createClient()
fs = require('fs')
_ = require('underscore')
marked = require('marked')
execFile = require('child_process').execFile;
expire = 3600
routes = (app) ->
	if app.settings.env is 'development'
		expire = 10
	app.get '/*', (req, res) ->
		page = 'index'
		get_templates {}, 'pages', (tpls) ->
			get_templates tpls, 'parts', (tpls) ->
				get_templates tpls, '_content', (tpls) ->
					get_templates tpls, '_sidebars', (tpls) ->
						_Speakers = Speakers.forge()
						_Speakers.getByType()
						.then (speakers) ->
							res.render "../views/#{page}",
								title: "World Domination Summit"
								env: '"'+process.env.NODE_ENV+'"'
								speakers: JSON.stringify(speakers)
								authd: 1
								tpls: JSON.stringify(tpls)


get_templates = (tpls, type, cb) ->
	rds.get 'tpls_'+type, (err) ->
		if type is '_content' or type is '_sidebars'
			path = "/../../" + type
		else
			path = "/../views/"+type
		path = __dirname + path
		execFile 'find', [ path ], (err, stdout, stderr) ->
			files = stdout.split '\n'
			rsp = {}

			# This will be called when all files are rendered
			finishedRendering = ->
				rds.set 'tpls', JSON.stringify(tpls), ->
					rds.expire 'tpls_'+type, expire, ->
						cb tpls

			# This renders each file
			renderTplFile = (files, index) ->
				if files[index]?
					file = files[index]
					if file.indexOf('.') > -1
						ext = file.split(type)[1].split('.')?[1]
						if ext is 'jade' or ext is 'md' or ext is 'html'
							tpl_opts = ''
							renderFile = file
							renderOpts =
								pretty: false

							# If md or html, it's a content page
							if ext is 'md' or ext is 'html'

								# Check if it's a sidebar and use the
								# right content template
								if file.indexOf('_sidebar') > -1
									tpl_type = 'sidebar'
									renderFile = __dirname + '/../views/sidebar.jade'
								else
									tpl_type = 'pages'
									renderFile = __dirname + '/../views/content.jade'

								pre_content = fs.readFileSync(file,'utf8');

								# Process markdown
								if ext is 'md'

									# Marked auto-parses links but we don't want that
									pre_content = pre_content.replace(/https\:\/\//g, 'https%//')
									pre_content = pre_content.replace(/http\:\/\//g, 'http%//')
									pre_content = marked(pre_content, {gfm: true})
									pre_content = pre_content.replace(/https\%\/\//g, 'https://')
									pre_content = pre_content.replace(/http\%\/\//g, 'http://')

								# Get the slug
								name = file.split(/_[a-z]*\//)[1].split('.')[0]
								content = ''

								# If a content page, figure out where the 
								# properties stop and the content begins
								tplStarted = false
								if tpl_type is 'pages'
									for line in pre_content.split("\n")
										if tplStarted
											content += line+"\n"
										else
											if line.replace('<p>', '').replace('</p>', '').indexOf('<') > -1
												content += line+"\n"
												tplStarted = true
											else
												tpl_opts += line+"\n"
									unless tplStarted
										content = tpl_opts
										tpl_opts = ''
								else
									content = pre_content

								# Append a separator after the options that 
								# we can use later
								if tpl_opts.length
									tpl_opts = tpl_opts + '----tpl_opts----'
									
								renderOpts.content = content
							else
								tpl_type = type
								name = _.last file.split '/'
								name = name.replace '.jade', ''


							jade.renderFile renderFile, renderOpts, (err, str) ->
								if not err
									tpls[tpl_type+'_'+name] = tpl_opts + str
								else
									tk 'ERR IN: '+file
									tk err
									tk '-----------------'
								renderTplFile files, (index + 1)
						else
							renderTplFile files, (index + 1)
					else
						renderTplFile files, (index + 1)
				else
					finishedRendering()
			renderTplFile files, 0
module.exports = routes
