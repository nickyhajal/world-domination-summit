https = require 'https'
http = require 'http'
crypto = require 'crypto'
Twit = require 'twit'
shell = (app, db) ->
	flickr_pub = app.settings.flickr_pub
	flickr_sec = app.settings.flick_secret
	twit = new Twit
		consumer_key: app.settings.twitter_consumer_key
		consumer_secret: app.settings.twitter_consumer_secret
		access_token: app.settings.twitter_token
		access_token_secret: app.settings.twitter_token_setting
	grab = ->
		grabs = 
			featured_tweet: ->
				tk 'Start twitter...'
				twit.get('favorites/list', {}, (err, twts) ->
					if twts
						for twt in twts
							data =
								tweet: twt.text
								tweeter: twt.user.screen_name
								tweeter_img: twt.user.profile_image_url_https.replace('_normal', '')
							uniqid = crypto.createHash 'md5'
							uniqid.update twt.id_str
							uniqid = uniqid.digest 'hex'
							tk data
							tk uniqid
							add 'featured_tweet', uniqid, data, (row) ->
							lastid = twt.id
					else
						tk 'No new tweets.'
				)
			flickr_stream: ->
				tk 'Start flickr...'
				http.request(
					host: 'api.flickr.com'
					path: '/services/rest/?method=flickr.photos.search&api_key='+flickr_pub+'&format=json&user_id=26292851@N04&tags=fave&extras=url_o'
				, (rsp) ->
					str = ''
					rsp.on 'data', (chunk)->
						str += chunk
					rsp.on 'end', ->
						if str.length
							str = str.substr(str.indexOf('(')+1)
							str = str.substr(0, str.length-1)
							photos = JSON.parse(str).photos.photo
							for photo in photos
								data =
									the_img: photo.url_o
									photo_title: photo.title
								uniqid = crypto.createHash 'md5'
								uniqid.update photo.url_o
								uniqid = uniqid.digest 'hex'
								add 'flickr_stream', uniqid, data, (row) ->
						else
							tk 'No new tweets.'
							
				).end()
				
				
		for type, fnc of grabs
			fnc()

		setTimeout ->
			grab()
		, 60000

	gto = (name, def = false, cb) ->
		db.query()
			.select('*')
			.from('wds_options')
			.where('option_name = ?', [name])
			.execute (err, rows) ->
				if rows? and rows.length
					row = rows[0]
					cb row.option_value
				else
					cb def

	pto = (name, value, cb) ->
		gto name, false, (val) ->
			if val
				db.query()
					.update('wds_options')
					.set({option_value: value})
					.where('option_name = ? ', [name])
					.execute (err, rows) ->
						cb rows
			else
				db.query()
					.insert('wds_options', ['option_name', 'option_value'], [name, value])
					.execute (err, rows) ->
						cb rows
	add = (type, uniqid, data, cb) ->
		data = JSON.stringify data
		db.query()
			.select('contentid')
			.from('content')
			.where('uniqid = ?', [uniqid])
			.execute (err, rows) ->
				tk rows.length
				if not rows.length
					db.query()
						.insert('content', ['type', 'uniqid', 'data'], [type, uniqid, data])
						.execute (err, rows) ->
							cb rows
	grab()

module.exports = shell