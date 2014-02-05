ap.Entry = XModel.extend
	defaults:
		model: 'Entries'
	url: '/api/entry'
	initialize: (opts = {})->
		duo = @get('duo')
		created = @get('created_at')
		updated = @get('updated_at')
		author = false
		if duo
			creator = duo.get('creator')
			acceptor = duo.get('acceptor')
			if creator.userid is @get('userid')
				author = creator
			else
				author = acceptor
		byline = 'Shared by ' + author.first_name
		date = _.nicetime(moment.utc(created))
		gravatar = 'http://www.gravatar.com/avatar/' + author.email_hash
		if created isnt updated
			date += ' (Updated '+_.nicetime(moment.utc(updated))+')'
		@set
			byline: byline
			date: date
			gravatar: gravatar

	getStatusString: ->
		if +@get('public')
			return 'Entry'
		else
			return 'Draft'
	saved: (rsp)->

# Create the Events collection and
# instantiate it
Entries = XCollection.extend
	model: ap.Entry
	url: '/api/entries/'
ap.Entries = new Entries()
