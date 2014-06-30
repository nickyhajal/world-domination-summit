Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Achievement = Shelf.Model.extend
  tableName: 'race_achievements'
  idAttribute: 'ach_id'
  hasTimestamps: true
  
Achievements = Shelf.Collection.extend
	model: Achievement
	processPoints: (user_id) ->
		dfr = Q.defer()
		[RaceTask, RaceTasks] = require('./racetasks')
		RaceTasks::getById()
		.then (tasksById) ->
			Achievements.forge()
			.query('where', 'user_id', user_id)
			.fetch()
			.then (rsp) ->
				points = 0
				for ach in rsp.models
					if ach.get('custom_points')? and +ach.get('custom_points') > 0
						points += +ach.get('custom_points')
					else
						points += (+tasksById[ach.get('task_id')].points) + (+ach.get('add_points'))
				dfr.resolve(points)
		return dfr.promise



module.exports = [Achievement, Achievements]