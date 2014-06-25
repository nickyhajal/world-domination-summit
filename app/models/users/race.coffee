crypto = require('crypto')
Q = require('q')
async = require('async')

##

checks = {}
race = 
  raceCheck: ->
    dfr = Q.defer()
    user = this
    muts = []
    achs = []

    @getAchievements()
    .then (achs) ->
      async.each checks, (check, cb) ->
        check(cb)
      , ->
        user.processPoints()
        .then ->
          dfr.resolve()
    return dfr.promise

  achieved: (task_id, achs) ->
    count = 0
    for ach in achs
      if task_id is ach.get('task_id')
        count += 1
    return count

  processPoints: ->
    dfr = Q.defer()
    Achievements.forge()
    .processPoints(@get('user_id'))
    .then (points) ->
      dfr.resolve(points)
    return dfr.promise

  getAchievements: ->
    dfr = Q.defer()
    Achievements.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (achs) ->
      dfr.resolve(achs.models)
    return dfr.promise

checks =
  check_distance: (cb) ->
    if not user.achieved('distance', 3)
      x =1

module.exports = race