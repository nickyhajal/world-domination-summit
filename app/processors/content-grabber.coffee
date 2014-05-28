https = require 'https'
http = require 'http'
crypto = require 'crypto'
Twit = require 'twit'

[Content, Contents] = require('../models/contents')

shell = (app, db) ->
	flickr_pub = app.settings.flickr_pub
	flickr_sec = app.settings.flick_secret

	twit = new Twit
		consumer_key: app.settings.twitter_consumer_key
		consumer_secret: app.settings.twitter_consumer_secret
		access_token: app.settings.twitter_token
		access_token_secret: app.settings.twitter_token_secret

	grab = ->
		tk 'Grab'
		grabs = 
			featured_tweet: ->
				tk 'Start twitter...'
				twit.get 'favorites/list', {}, (err, twts) ->
					if twts
						for twt in twts
							data =
								tweet: twt.text
								tweeter: twt.user.screen_name
								tweeter_img: twt.user.profile_image_url_https.replace('_normal', '')
							uniqid = crypto.createHash 'md5'
							uniqid.update twt.id_str
							uniqid = uniqid.digest 'hex'
							add 'featured_tweet', uniqid, data, (row) ->
							lastid = twt.id
					else
						tk 'No new tweets.'
			flickr_stream: ->
				tk 'Start flickr...'
				http.request(
					host: 'api.flickr.com'
					path: '/services/rest/?method=flickr.photos.search&api_key='+flickr_pub+'&per_page=500&format=json&user_id=26292851@N04&tags=fave&extras=url_o,url_c,url_l'
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
								orientation = 'portrait'
								if +photo.width_l > +photo.height_l
									orientation = 'landscape'
								data =
									the_img: photo.url_o
									the_img_small: photo.url_c
									the_img_med: photo.url_l
									photo_title: photo.title
									orientation: orientation
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

	add = (type, uniqid, data, cb) ->
		data = JSON.stringify data
		Content.forge({uniqid: uniqid})
		.fetch()
		.then (existing) ->
			unless existing
				new_content = Content.forge
					type: type
					uniqid: uniqid
					data: data
				new_content.save()
				.then (row) ->
					cb row
				, (err) ->
					err
	grab()

module.exports = shell