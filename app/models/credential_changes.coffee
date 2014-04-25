###

	Credential Changes allow users to reset their passwords 
	in a secure, trackable way

###

Shelf = require('./shelf')
Q = require('q')
crypto = require('crypto')
moment = require('moment')

CredentialChange = Shelf.Model.extend
	tableName: 'credential_changes'
	idAttribute: 'credential_change_id'
	hasTimestamps: true

	###
		Create a valid credential hash for a user
		then email them the hash

		TODO: Invalidate pre-existing hashes?
	###
	create: (user) ->
		dfr = Q.defer()
		user_id = user.get('user_id')
		uniq = (+(new Date())) + user_id
		hash = crypto.createHash('md5').update(uniq+'').digest('hex')
		@set
			user_id: user_id
			hash: hash
		@save()
		.then (user) ->
			dfr.resolve()
		, (err) ->
			tk err
		return dfr.promise

  isValid: ->
  	return @get('used') is '0000-00-00 00:00:00'

	use: ->
		dfr = Q.defer()
		@set
			used: moment().format('YYYY-MM-DD HH:mm:ss')
		@save()
		.then (row) ->
			dfr.resolve row
		return dfr.promise

CredentialChanges = Shelf.Collection.extend
  model: CredentialChange

module.exports = [CredentialChange, CredentialChanges]