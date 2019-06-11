knex = require('knex');
moment = require('moment');
Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')
redis = require("redis")
rds = redis.createClient()

Achievement = Shelf.Model.extend
  tableName: 'race_achievements'
  idAttribute: 'ach_id'
  hasTimestamps: true
  submission: ->
  	[RaceSubmission, RaceSubmissions] = require('./race_submissions')
  	return @hasOne(RaceSubmission, 'submission_id')

Achievements = Shelf.Collection.extend
	model: Achievement
	generateRanksSince: (time) ->
		dfr = Q.defer()
		tk '>> GEN RANK SINCE'+time
		process.knex('race_achievements as a')
		.select(knex.raw('user_id, sum(points + custom_points + add_points) as total'))
		.leftJoin('racetasks as t', 'a.task_id', 't.racetask_id')
		.where('add_points', '>', '-1')
		.where('created_at', '>', time)
		.orderBy('total', 'DESC')
		.groupBy('user_id')
		.then (ranks) ->
			dfr.resolve(ranks)
		return dfr.promise
	generateRanks: ->
		dfr = Q.defer()
		Promise.all([
			@generateRanksSince(moment().startOf('year').format('YYYY-MM-DD hh:mm:ss')),
			@generateRanksSince(moment().subtract(1, 'h').format('YYYY-MM-DD hh:mm:ss')),
			@generateRanksSince(moment().subtract(24, 'h').format('YYYY-MM-DD hh:mm:ss')),
		])
		.then ([all, day, hour]) ->
			ranks = {all: all, day: day, hour: hour}
			process.fire.database().ref().child('race/state/ranks').set(ranks)
			rds.set 'ranks', JSON.stringify(ranks), ->
			dfr.resolve(ranks)
		return dfr.promise
	processPoints: (user_id) ->
		dfr = Q.defer()
		@generateRanks()
		.then (ranks) ->
			out = 0
			ranks.all.forEach (row) ->
				if (row.user_id == user_id)
					out = row.total
			dfr.resolve(out)
		return dfr.promise



module.exports = [Achievement, Achievements]