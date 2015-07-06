ap.Views.community_hub = XView.extend
	initialize: ->
		_.whenReady 'assets', =>
			interest = ap.Interests.getBySlug(@options.interest)
			@options.out = _.template @options.out, {interest_name: interest.get('interest'), interest: interest.get('interest_id')}
			@initRender()
