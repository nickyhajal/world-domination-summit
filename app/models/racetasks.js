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

// setTimeout(() => {
//   const layout = `# Your Stats
// ## Tasks Completed
// blocks=Past Hour:u.achs.hour|Past Day:u.achs.day|All-Time:u.achs.all
// ## Rank
// blocks=Past Hour:u.ranks.hour|Past Day:u.ranks.day|All-Time:u.ranks.all
// # Global
// blocks=Past Hour:a.achs.hour|Past Day:a.achs.day|All-Time:a.achs.all
// ## Top 5 - Past Hour
// ranks=a.ranks.hour
// ## Top 5 - Past Day
// ranks=a.ranks.day
// ## Top 5 - All-Time
// ranks=a.ranks.all`;
//   const instructions = `<div style='margin-top: 14px'></div>

//   ## Welcome to the Unconventional Race!

//   The Unconventional Race will guide you to different parts of Portland to complete exciting challenges for points and prizes. To celebrate its return, this year we have some new surprises in store. Read on to learn how to play!

//   ### Complete Challenges to Win Points and Prizes

//   The race is comprised of a wide variety of challenges, ranging from easy to difficult to impossible. Your mission is to choose the challenges that excite you the most and complete them to earn points along the way. Try wandering out of your comfort zone. After all, fortune favors the bold!

//   Choose a challenge, and use the app to snap a photo or video to prove that you've successfully completed it. Don't forget to get creative! Our expert jury of race judges will be reviewing each submission, and we'll be highlighting some of the best entries throughout WDS.

//   During WDS, you'll be able to win prizes throughout the WDS weekend. Be on the lookout for notifications letting you know you've won a prize! Make sure to keep playing, and check back frequently because you never know when we'll add new challenges and prizes.

//   ### You Can Start Now!

//   WDS is almost here, but you can start winning points before you even arrive. Complete all the pre-WDS challenges and get warmed up before the official start of the race!

//   ### Be Respectful and Have Fun!

//   As you play, please remember to adhere to the WDS Code of Conduct. Also, don't forget to stay safe!

//   ## Good Luck!

//   P.S. Have questions? Need assistance with anything? Reach out to our concierge team at concierge@wds.fm.`;
//   process.fire
//     .database()
//     .ref()
//     .child('race/rundown/layout')
//     .set(layout);
//   process.fire
//     .database()
//     .ref()
//     .child('race/instructions')
//     .set(instructions);
// }, 2000);

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
