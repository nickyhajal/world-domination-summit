Shelf = require('./shelf')

RaceSubmission = Shelf.Model.extend
	tableName: 'race_submissions'
	hasTimestamps: true
	idAttribute: 'submission_id'
	permittedAttributes: [
		'submission_id', 'user_id', 'ach_id', 'hash', 'ext', 'rating'
	]

RaceSubmissions = Shelf.Collection.extend
  model: RaceSubmission

module.exports = [RaceSubmission, RaceSubmissions]