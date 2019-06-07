/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Shelf = require('./shelf');
const redis = require('redis');
const rds = redis.createClient();
const Q = require('q');

const RaceTask = Shelf.Model.extend({
  tableName: 'racetasks',
  idAttribute: 'racetask_id',
  permittedAttributes: [
    'racetask_id',
    'section',
    'type',
    'task',
    'slug',
    'points',
    'note',
    'active',
    'address',
    'geopoint',
    'attendee_max',
    'global_max',
    'submissitons',
  ],
});

var RaceTasks = Shelf.Collection.extend({
  model: RaceTask,
  getById(type) {
    let key;
    if (type == null) {
      type = false;
    }
    const dfr = Q.defer();
    if (type === 'instagram') {
      key = 'tasksByIgId';
    } else if (type === 'slug') {
      key = 'tasksBySlug';
    } else {
      key = 'tasksById';
    }
    rds.get(key, function(err, tasksById) {
      if (tasksById != null && typeof JSON.parse(tasksById) === 'object') {
        dfr.resolve(JSON.parse(tasksById));
      } else {
        RaceTasks.forge()
          .fetch()
          .then(function(tasks) {
            tasksById = {};
            for (let task of Array.from(tasks.models)) {
              var id;
              if (type === 'slug') {
                id = task.get('slug');
              } else if (type === 'instagram') {
                id = task.get('slug').replace('-', '');
              } else {
                id = task.get('racetask_id');
              }
              tasksById[id] = task.toJSON();
            }
            rds.set(key, JSON.stringify(tasksById), () =>
              rds.expire(key, 500, () => dfr.resolve(tasksById))
            );
          });
      }
    });
    return dfr.promise;
  },
});

module.exports = [RaceTask, RaceTasks];
