Shelf = require('./shelf')
redis = require("redis")
rds = redis.createClient()
Q = require('q')

RaceTask = Shelf.Model.extend
  tableName: 'racetasks'
  idAttribute: 'racetask_id'
  permittedAttributes: [
    'racetask_id', 'section', 'type', 'task', 'slug', 'points', 'note', 'active',
    'active', 'attendee_max', 'global_max', 'submissitons'
  ]

RaceTasks = Shelf.Collection.extend
	model: RaceTask
	getById: ->
		dfr = Q.defer()
		rds.get 'tasksById', (err, tasksById) ->
			if tasksById? and typeof JSON.parse(tasksById) is 'object'
				dfr.resolve(JSON.parse(tasksById))
			else
				RaceTasks.forge()
				.fetch()
				.then (tasks) ->
					tasksById = {}
					for task in tasks.models
						tasksById[task.get('racetask_id')] = task.toJSON()
					rds.set 'tasksById', JSON.stringify(tasksById), ->
						rds.expire 'tasksById', 500, ->
							dfr.resolve(tasksById)
		return dfr.promise

module.exports = [RaceTask, RaceTasks]