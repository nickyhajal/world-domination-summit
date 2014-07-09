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
	getById: (type = false) ->
		dfr = Q.defer()
		if type is 'instagram'
			key = 'tasksByIgId'
		else
			key = 'tasksById'
		rds.get key, (err, tasksById) ->
			if tasksById? and typeof JSON.parse(tasksById) is 'object'
				dfr.resolve(JSON.parse(tasksById))
			else
				RaceTasks.forge()
				.fetch()
				.then (tasks) ->
					tasksById = {}
					for task in tasks.models
						if type is 'instagram'
							id = task.get('slug').replace('-', '')
						else
							id = task.get('racetask_id')
						tasksById[id] = task.toJSON()
					rds.set key, JSON.stringify(tasksById), ->
						rds.expire key, 500, ->
							dfr.resolve(tasksById)
		return dfr.promise

module.exports = [RaceTask, RaceTasks]