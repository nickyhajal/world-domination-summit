###

	Handle file uploads

###
fs = require('fs')
crypto = require('crypto')
gm = require('gm')
request = require('request')

[User, Users] = require('../models/users')
routes = (app) ->
	app.all '/upload-avatar', (req, res) ->

		if req.files
			console.log(req.files.pic.path)
			ext = req.files.pic.path.split('.')
			ext = ext[ext.length - 1]
			console.log(req.session)
			console.log(req.me)
			Users.forge().getMe(req)
			.then (me) ->
				console.log(me)
				url = "/images/avatars/"+me.get('user_id')+'.'+ext
				console.log(url);
				newPath = __dirname + '/../..' + url
				console.log(req.files.pic.path)
				console.log(newPath)
				gm(req.files.pic.path)
				.resize('400^')
				.gravity('Center')
				.crop(400, 400, 0, 0)
				.write newPath, (err) ->
					console.log(err)
					url = url.split('?')
					console.log(url)
					console.log(url[0])
					me.set
						pic: url[0]
					me.save()
					.then ->
						request 'http://avatar.wds.fm/flush/'+me.get('user_id'), (error, response, body) ->
						res.render "../views/upload-success"
							layout: false
							url: (url + '?'+crypto.createHash('md5').update((new Date().getTime())+'').digest("hex"))
							title: "World Domination Summit - Upload Success"
		else
			res.render "../views/upload",
				title: "World Domination Summit - Avatar Upload"
				layout: false

module.exports = routes
