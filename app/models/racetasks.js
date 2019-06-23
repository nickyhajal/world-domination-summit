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

setTimeout(() => {
  const layout = `# Your Stats
## Tasks Completed
blocks=Past Hour:u.achs.hour|Past Day:u.achs.day|All-Time:u.achs.all
## Rank
blocks=Past Hour:u.ranks.hour|Past Day:u.ranks.day|All-Time:u.ranks.all
# Global
blocks=Past Hour:a.achs.hour|Past Day:a.achs.day|All-Time:a.achs.all
## Top 5 - Past Hour
ranks=a.ranks.hour
## Top 5 - Past Day
ranks=a.ranks.day
## Top 5 - All-Time
ranks=a.ranks.all`;
  const instructions = `<div style='margin-top: 14px'></div>

## Welcome to the Unconventional Race!

The Unconventional Race is amazing!

### Complete Tasks to Earn Points!

Some sample text explaining rules, submitting.

You'll get points immediately but we've got a crack team reviewing submissions.

Standout submissions will be posted to the Dispatch. 

### Groups Earn More Points!

Coming soon: join groups to earn more points. 2x, 3x, or 4x points up to 4 players.

After 4 players, an additional point per member (fill in with actual details).

### Prizes

Coming Soon: Randomly win real prizes! You'll receive a notification after submitting if you received a prize.

You can monitor all prizes from the app and collect at the WDS books store.

### Be Respectful and Have Fun!

General ground rules? Code of conduct?`;
  process.fire
    .database()
    .ref()
    .child('race/rundown/layout')
    .set(layout);
  process.fire
    .database()
    .ref()
    .child('race/instructions')
    .set(instructions);
}, 2000);

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
