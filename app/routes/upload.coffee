###

	Handle file uploads

###
fs = require('fs')
crypto = require('crypto')
gm = require('gm')
request = require('request')
multer  = require('multer')
upload = multer({ dest: '/tmp_uploads/' })

[User, Users] = require('../models/users')
routes = (app) ->
	app.all '/rotate', (req, res) ->
			user_id = req.query.user_id
			Users.forge({user_id: user_id})
			.fetch()
			.then (user) ->
				console.log(user)
				path = user.get('pic')
				console.log(path)
				if path.indexOf '/images/' is 0
					fullPath = __dirname + '/../..' + path
					console.log(fullPath)
					gm(fullPath)
					.rotate(90)
					.write fullPath, (err) ->
						request 'https://avatar.wds.fm/flush/'+me.get('user_id'), (error, response, body) ->
						res.send('rotated');
				else
					res.send('offsite image')
						# res.render "../views/upload-success"
						# 	layout: false
						# 	url: (url + '?'+crypto.createHash('md5').update((new Date().getTime())+'').digest("hex"))
						# 	title: "World Domination Summit - Upload Success"
	app.all '/upload-avatar', upload.single('pic'), (req, res) ->

		if req.file
			ext = req.file.originalname.split('.')
			ext = ext[ext.length - 1]
			Users.forge().getMe(req)
			.then (me) ->
				request 'https://avatar.wds.fm/flush/'+me.get('user_id'), (error, response, body) ->
				url = "/images/avatars/"+me.get('user_id')+'.'+ext
				newPath = __dirname + '/../..' + url
				gm(req.file.path)
				.resize('1200^')
				.write newPath, (err) ->
					url = url.split('?')
					me.set
						pic: url[0]
					me.save()
					.then ->
						request 'https://avatar.wds.fm/flush/'+me.get('user_id'), (error, response, body) ->

						res.send('');
						# res.render "../views/upload-success"
						# 	layout: false
						# 	url: (url + '?'+crypto.createHash('md5').update((new Date().getTime())+'').digest("hex"))
						# 	title: "World Domination Summit - Upload Success"
		else
			res.render "../views/upload",
				title: "World Domination Summit - Avatar Upload"
				layout: false

module.exports = routes
