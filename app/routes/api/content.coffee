gm = require('gm')
redis = require("redis")
rds = redis.createClient()

#

[Content, Contents] = require('../../models/contents')
[Answer, Answers] = require('../../models/answers')
[User, Users] = require('../../models/users')

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
		rds.get 'featured_content', (err, f_content) ->
			if f_content? and typeof JSON.parse(f_content) is 'object'
				res.r = JSON.parse(f_content)
				next()
			else
				_Users = Users.forge()
				_Contents = Contents.forge()
				_Answers = Answers.forge()
				_Contents
				.query (qb) =>
					qb.column(qb.knex.raw('((24 + 1 + GREATEST(TIMESTAMPDIFF(HOUR, NOW(), CREATED_AT), TIMESTAMPDIFF(HOUR, NOW(), DATE_SUB(NOW(), INTERVAL 1 DAY)))) * RAND()) weight'))
					qb.where('content_id', '>', '0')
					qb.orderBy('weight', 'desc')
				.fetch(
					columns: ['content_id', 'type', 'data']
				)
				.then (contents) ->
					tk process.yr
					_Users
					.query('where', 'pub_loc', '=', '1')
					.query('where', 'attending15', '=', '1')
					.query('where', 'pic', '<>', '')
					.query('orderBy', 'user_id', 'desc')
					.fetch(
						columns: ['user_id', 'first_name', 'last_name', 'user_name', 'distance', 'lat', 'lon', 'pic']
					)
					.then (attendees) ->
						_Answers
						.query('join', 'users', 'answers.user_id', '=', 'users.user_id')
						.query('where', 'users.attending15', '=', '1')
						.query('where', 'dsp', '=', '1')
						.query('orderBy', 'users.user_id', 'desc')
						.fetch(
							columns: ['users.user_id', 'question_id', 'answer']
						)
						.then (answers) ->
							res.r.answers = answers
							res.r.content = contents
							res.r.attendees = attendees
							rds.set 'featured_content', JSON.stringify(res.r), ->
								rds.expire 'featured_content', 0
							next()
						, (err) ->
							console.error(err)
					, (err) ->
						console.error(err)
				, (err) ->
					console.error(err)
module.exports = content
