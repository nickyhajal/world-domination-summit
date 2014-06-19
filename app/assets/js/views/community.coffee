ap.Views.community = XView.extend
	initialize: ->
		interest = ap.Interests.getBySlug(@options.interest)
		@options.out = _.template @options.out, {interest_name: interest.get('interest'), interest: interest.get('interest_id')}
		@initRender()

	whenFinished: ->
		$('.dispatch-feed').data('feed').stop()