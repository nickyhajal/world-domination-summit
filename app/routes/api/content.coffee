[Content, Contents] = require('../../models/contents')
[Answer, Answers] = require('../../models/answers')
[User, Users] = require('../../models/users')
gm = require('gm')

content = 
	parse: (req, res, next) ->
			_Contents = Contents.forge()
			_Contents
			.query('where', 'type', '=', 'flickr_stream')
			.query('where', 'content_id', '>', '390')
			.fetch()
			.then (contents) ->
				processImg = (content) ->
					data = JSON.parse content.get('data')
					url = data.the_img
					unless data.width?
						gm(url)
						.size (err, size) ->
							data.height = size.height
							data.width = size.width
							if size.width > size.height
								data.orientation = 'landscape'
							else
								data.orientation = 'portrait'
							content.set
								data:  JSON.stringify(data)
							content.save()

				for cont in contents.models
					processImg cont
				next()
	get: (req, res, next) ->
			offset = Math.floor( Math.random() * (0 - 3000 + 1) ) + 3000
			_Users = Users.forge()
			_Contents = Contents.forge()
			_Answers = Answers.forge()
			_Contents
			.query('where', 'content_id', '>', '0')
			.query('orderBy', 'content_id', 'desc')
			.fetch(
				columns: ['content_id', 'type', 'data']
			)
			.then (contents) ->
				_Users
				.query('where', 'pub_loc', '=', '1')
				.query('where', 'attending14', '=', '1')
				.query('where', 'pic', '<>', '')
				.query('orderBy', 'user_id', 'desc')
				.fetch(
					columns: ['user_id', 'first_name', 'last_name', 'user_name', 'distance', 'lat', 'lon', 'pic']
				)
				.then (attendees) ->
					_Answers
					.query('join', 'users', 'answers.user_id', '=', 'users.user_id')
					.query('where', 'users.attending14', '=', '1')
					.query('where', 'dsp', '=', '1')
					.query('orderBy', 'users.user_id', 'desc')
					.fetch(
						columns: ['users.user_id', 'question_id', 'answer']
					)
					.then (answers) ->
						tk answers
						res.r.answers = answers
						res.r.content = contents
						res.r.attendees = attendees
						next()
					, (err) ->
						tk err
				, (err) ->
					tk err
			, (err) ->
				tk err
module.exports = content