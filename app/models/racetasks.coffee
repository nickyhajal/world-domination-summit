Shelf = require('./shelf')

RaceTask = Shelf.Model.extend
  tableName: 'racetasks'
  idAttribute: 'racetask_id'
  permittedAttributes: [
    'racetask_id', 'section', 'type', 'task', 'slug', 'points', 'note', 'active',
    'active', 'attendee_max', 'global_max', 'submissitons'
  ]

RaceTasks = Shelf.Collection.extend
  model: RaceTask

module.exports = [RaceTask, RaceTasks]