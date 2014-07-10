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
		else if type is 'slug'
			key = 'tasksBySlug'
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
						tk type
						if type is 'slug'
							tk 'create with slug'
							id = task.get('slug')
						else if type is 'instagram'
							id = task.get('slug').replace('-', '')
						else
							tk 'create with id'
							id = task.get('racetask_id')
						tasksById[id] = task.toJSON()
					rds.set key, JSON.stringify(tasksById), ->
						rds.expire key, 500, ->
							dfr.resolve(tasksById)
		return dfr.promise

module.exports = [RaceTask, RaceTasks]