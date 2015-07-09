ap.Views.Dispatch = XView.extend
	controlsTimo: 0
	events:
		'submit .dispatch-post-form': 'postFeed'
		'focus .dispatch-post-inp': 'focusControls'
		'blur .dispatch-post-inp': 'blurControls'

	initialize: ->
		defaults =
			channel_id: 0
			channel_type: 'global'
		@options = _.defaults @options, defaults
		render = true
		if $(@el).data('desktop_only')? and not ap.isDesktop
			render = false
		_.whenReady 'me', =>
			if render
				@render()
	render: ->
		_.whenReady 'tpls', =>
			html = _.t 'parts_dispatch', {}
			$(@el).html html
			if @options.placeholder
				$('.dispatch-post-inp', $(@el)).attr('placeholder', @options.placeholder)
			_.whenReady 'users', =>
				$('.dispatch-feed', @el).feed
					user_id: @options.user_id
					channel_id: @options.channel_id
					channel_type: @options.channel_type
				$('.dispatch-post-inp', @el).autosize()
				if @options.channel_type is 'user'
					$('.dispatch-post-form', $(@el)).remove()

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
		if post.content.length > 0
			post.channel_id = @options.channel_id
			post.channel_type = @options.channel_type
			setTimeout =>
				@blurControls(e)
				$('.dispatch-post-inp', $(e.currentTarget)).val('').css('height', '43px')
			, 500
			ap.api 'post feed', post
