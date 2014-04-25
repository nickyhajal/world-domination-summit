ap.Views.Dispatch = XView.extend
	controlsTimo: 0
	events:
		'submit .dispatch-post-form': 'postFeed'
		'focus .dispatch-post-inp': 'focusControls'
		'blur .dispatch-post-inp': 'blurControls'

	initialize: ->
		defaults =
			post_channel_id: 0
			post_channel_type: 'global'
		@options = _.defaults @options, defaults
		@render()
	render: ->
		html = _.t 'parts_dispatch', {}
		$(@el).html html
		$('.dispatch-feed', @el).feed()
		$('.dispatch-post-inp', @el).autosize()

	focusControls: (e) ->
		$(e.currentTarget).closest('.dispatch-controls').addClass('focused')
	blurControls: (e) ->
		@controlsTimo = setTimeout ->
			$(e.currentTarget).closest('.dispatch-controls').removeClass('focused')
		, 140

	postFeed: (e) ->
		clearTimeout @controlsTimo
		e.preventDefault()
		post = $(e.currentTarget).formToJson()
		post.channel = @options.post_channel_id
		post.channel_type = @options.post_channel_type
		setTimeout =>
			@blurControls(e)
			$('.dispatch-post-inp', $(e.currentTarget)).val('').css('height', '43px')
		, 500
		ap.api 'post feed', post
