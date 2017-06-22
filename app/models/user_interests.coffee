Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
redis = require("redis")
rds = redis.createClient()
[Interest, Interests] = require('./interests')

UserInterest = Shelf.Model.extend
  tableName: 'user_interests'
  permittedAttributes: [
    'user_interest_id', 'interest_id'
  ]
  idAttribute: 'user_interest_id'

UserInterests = Shelf.Collection.extend
  model: UserInterest
  countInterests: (limitId = false) ->
    dfr = Q.defer()
    columns = { columns: ['interest_id']}
    @query (qb) -> 
      qb
      .count('interest_id as memberCount')
      .leftJoin('users', 'users.user_id', 'user_interests.user_id')
      .where('attending17', '1')
      .groupBy('interest_id') 
      
      if limitId
        qb.where('interest_id', limitId)

    .fetch(columns)
    .then (rsp) ->
      dfr.resolve(rsp.models)
      for row in rsp.models
        Interest.forge({ interest_id: row.get('interest_id')})
        .save({members: row.get('memberCount')}, {patch: true, method: 'update'})
      rds.expire 'interests', 0
        
    dfr.promise

module.exports = [UserInterest, UserInterests]