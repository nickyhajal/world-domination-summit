###

	Mission Ops Page

###

ap.Views.hub = XView.extend
	events: 
		'click .broadcast-box-close': 'closeBroadcasts'
	
	initialize: ->
		@options.sidebar = 'hub'
		@initRender()
		setTimeout =>
			@initBroadcasts()
		, 750
	initBroadcasts: ->
		@broadcast_list = []
		@broadcasts = {}
		for name,page of ap.templates
			if name.indexOf('pages_broadcasts/') is 0
				options = ap.template_options[name]
				formatted_date = moment(options.date, 'M-D-YY').format('YYYY-MM-DD')
				options.date = moment(options.date, 'M-D-YY').format('MMMM Do YYYY')
				options.url = '/'+name.replace('pages_', '')
				@broadcast_list.push (formatted_date+'`'+name)
				@broadcasts[name] = 
					content: page
					options: options
		html = _.t 'parts_broadcast-box', @broadcasts[_.ari(@broadcast_list[0].split('`'), 1)].options

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
	closeBroadcasts: ->
		$('h2', $(@el))
			.first()
			.html('Attendee Hub')
			.removeClass('broadcast-active')
		$('.broadcast-box').addClass('broadcast-box-closed')
		setTimeout ->
			$('.broadcast-box').remove()
		, 205


	whenFinished: ->
		$(window).unbind('hashchange')
		$('#counter-shell').show()
		$('.settings-link').unbind()
		$('html').removeClass('attended-before')