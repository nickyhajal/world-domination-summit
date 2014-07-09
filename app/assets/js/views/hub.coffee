###

	Mission Ops Page

###

ap.Views.hub = XView.extend
	events: 
		'click .broadcast-box-close': 'closeBroadcasts'
		'click .broadcast-area a': 'saveLastBroadcast'
	
	initialize: ->
		@options.sidebar_filler = ap.me.attributes
		@options.sidebar = 'hub'
		@initRender()
		_.whenReady 'tpls', =>
			setTimeout =>
				@initBroadcasts()
			, 750
		
	initBroadcasts: ->
		@broadcast_list = []
		@broadcasts = {}
		for name,page of ap.templates
			if name.indexOf('pages_broadcasts/') is 0
				options = _.clone ap.template_options[name]
				options.date_iso = moment(options.date, 'M-D-YY').format('YYYY-MM-DD')
				options.date = moment(options.date, 'M-D-YY').format('MMMM Do YYYY')
				options.url = '/'+name.replace('pages_', '')
				@broadcast_list.push (options.date_iso+'`'+name)
				@broadcasts[name] = 
					content: page
					options: options
		@broadcast_list.sort().reverse()
		nextBroadcast = @broadcasts[_.ari(@broadcast_list[0].split('`'), 1)]
		if nextBroadcast.options.date_iso > ap.me.get('last_broadcast')
			@showBroadcast(nextBroadcast)

	showBroadcast: (broadcast) ->
			html = _.t 'parts_broadcast-box', broadcast.options
			$b = $('<div/>').append(html)
			$('h2', $(@el))
				.first()
				.html('Attendee Hub: New Broadcast!')
				.addClass('broadcast-active')
				.after($b)
			bbox = $('.broadcast-box')
			bbox.css('height', ('0px'))
			setTimeout ->
				bbox.css('height', ('110px'))
			, 10

	closeBroadcasts: (e) ->
		$('h2', $(@el))
			.first()
			.html('Attendee Hub')
			.removeClass('broadcast-active')
		$('.broadcast-box').addClass('broadcast-box-closed')
		setTimeout ->
			$('.broadcast-box').remove()
		, 205
		@saveLastBroadcast(e)

	saveLastBroadcast: (e) ->
		date = $(e.currentTarget).closest('.broadcast-box').data('date')
		ap.me.set('last_broadcast', date)
		if ap.me.changedSinceSave.last_broadcast?
			ap.me.save ap.me.changedSinceSave, {patch:true}


	whenFinished: ->
		$(window).unbind('hashchange')
		tk ap.isMobile
		if not ap.isMobile
			$('#counter-shell').show()
		$('.settings-link').unbind()
		$('html').removeClass('attended-before')
