[Content, Contents] = require('../../models/contents')
[Answer, Answers] = require('../../models/answers')
[User, Users] = require('../../models/users')
gm = require('gm')

content = 
	parse: (req, res, next) ->
			_Contents = Contents.forge()
			_Contents
			.query('where', 'type', '=', 'flickr_stream')
			.query('where', 'contentid', '>', '390')
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
			.query('where', 'contentid', '>', '0')
			.query('orderBy', 'contentid', 'desc')
			.fetch(
				columns: ['contentid', 'type', 'data']
			)
			.then (contents) ->
				_Users
				.query('where', 'pub_loc', '=', '1')
				.query('where', 'attending14', '=', '1')
				.query('where', 'pic', '<>', '')
				.query('orderBy', 'attendeeid', 'desc')
				.fetch(
					columns: ['attendeeid', 'fname', 'lname', 'uname', 'distance', 'lat', 'lon', 'pic']
				)
				.then (attendees) ->
					_Answers
					.query('join', 'attendees', 'answers.userid', '=', 'attendees.attendeeid')
					.query('where', 'attendees.attending14', '=', '1')
					.query('limit', '500')
					.query('offset', offset)
					.query('orderBy', 'attendeeid', 'desc')
					.fetch(
						columns: ['userid', 'questionid', 'answer']
					)
					.then (answers) ->
						res.r.answers = answers
						res.r.content = contents
						res.r.attendees = attendees
						next()
				, (err) ->
					tk err
			, (err) ->
				tk err
module.exports = content