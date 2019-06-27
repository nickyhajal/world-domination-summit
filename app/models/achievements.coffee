knex = require('knex');
moment = require('moment');
Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')
redis = require("redis")
rds = redis.createClient()

raceRef = require('../util/raceRef')

getNumberWithOrdinal = (n) ->
    s=["th","st","nd","rd"]
    v=n%100;
    return n+(s[(v-20)%10]||s[v]||s[0]);

Achievement = Shelf.Model.extend
  tableName: 'race_achievements'
  idAttribute: 'ach_id'
  hasTimestamps: true
  submission: ->
  	[RaceSubmission, RaceSubmissions] = require('./race_submissions')
  	return @hasOne(RaceSubmission, 'submission_id')

Achievements = Shelf.Collection.extend
	model: Achievement
	achsSince: (time, user_id) ->
		dfr = Q.defer()
		q = process.knex('race_achievements as a')
		.count('a.ach_id as count')
		.where('created_at', '>', time)
		.where('add_points', '>', '-1')
		if (user_id)
			q.where('user_id', user_id)
		q.then (res) ->
			dfr.resolve(res[0].count)
		return dfr.promise

	generateActivity: () ->
		dfr = Q.defer()
		process.knex('race_achievements as a')
		.select(process.knex.raw('user_id, task_id, points, add_points, custom_points'))
		.leftJoin('racetasks as t', 'a.task_id', 't.racetask_id')
		.where('add_points', '>', '-1')
		.where('type', '<>', 'auto')
		.limit('20')
		.orderBy('ach_id', 'DESC')
		.then (res) ->
			dfr.resolve(res)
		return dfr.promise
		
	generateRanksSince: (time, user_id) ->
		dfr = Q.defer()
		tk (process.knex('race_achievements as a').select(process.knex.raw('user_id, sum(points + custom_points + add_points) as total'))
		.leftJoin('racetasks as t', 'a.task_id', 't.racetask_id')
		.where('add_points', '>', '-1')
		.where('created_at', '>', time)
		.orderBy('total', 'DESC')
		.groupBy('user_id').toString())
		q = process.knex('race_achievements as a')
		.select(process.knex.raw('user_id, sum(points + custom_points + add_points) as total'))
		.leftJoin('racetasks as t', 'a.task_id', 't.racetask_id')
		.where('add_points', '>', '-1')
		.where('created_at', '>', time)
		.orderBy('total', 'DESC')
		.groupBy('user_id')
		q.then (res) ->
			dfr.resolve(res)
		return dfr.promise
	generateRanks: ->
		dfr = Q.defer()
		tk moment().subtract(1, 'h').format('YYYY-MM-DD hh:mm:ss')
		Q.all([
			@generateRanksSince(moment().startOf('year').format('YYYY-MM-DD hh:mm:ss')),
			@generateRanksSince(moment().utc().subtract(31, 'h').format('YYYY-MM-DD hh:mm:ss')),
			@generateRanksSince(moment().utc().subtract(8, 'h').format('YYYY-MM-DD hh:mm:ss')),
		])
		.then ([all, day, hour]) ->
			ranks = {all: all, day: day, hour: hour}
			rds.set 'ranks', JSON.stringify(ranks), ->
			dfr.resolve(ranks)
		return dfr.promise
	generateRundown: ->
		dfr = Q.defer()
		Q.all([
			@achsSince(moment().startOf('year').format('YYYY-MM-DD hh:mm:ss')),
			@achsSince(moment().subtract(24, 'h').format('YYYY-MM-DD hh:mm:ss')),
			@achsSince(moment().subtract(1, 'h').format('YYYY-MM-DD hh:mm:ss')),
			@generateActivity()
		]).then ([all, day, hour, activity]) =>
			dfr.resolve({
				achs: { all: all, day: day, hour: hour},
				activity: activity
			})
		return dfr.promise
	updateFire: (data) ->
		process.fire.database().ref().child(raceRef()+'/rundown/stats').set(data)
	processPoints: (user_id) ->
		dfr = Q.defer()
		@generateRanks()
		.then (ranks) =>
			out = {
				points: {all: 0, day: 0, hour: 0}
				ranks: {all: 0, day: 0, hour: 0}
			}
			c = 0
			# tk ranks
			ranks.all.forEach (row) =>
				c += 1
				if (row.user_id == user_id)
					out.ranks.all = getNumberWithOrdinal c
					out.points.all = row.total
			c = 0
			ranks.day.forEach (row) =>
				c += 1
				if (row.user_id == user_id)
					out.ranks.day = getNumberWithOrdinal c
					out.points.day = row.total
			c = 0
			ranks.hour.forEach (row) =>
				c += 1
				if (row.user_id == user_id)
					out.ranks.hour = getNumberWithOrdinal c
					out.points.hour = row.total
			@generateRundown()
			.then (res) =>
				res.ranks = ranks
				@updateFire(res)
			dfr.resolve(out)
		return dfr.promise



module.exports = [Achievement, Achievements]