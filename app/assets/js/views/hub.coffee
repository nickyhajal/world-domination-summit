###

	Mission Ops Page

###

ap.Views.hub = XView.extend
	location: false
	events: 
		'click .broadcast-box-close': 'closeBroadcasts'
		'click .broadcast-area a': 'saveLastBroadcast'
		'click #checkin-button': 'showPlaceSelect'
		'click #checkin-toggle-all-places': 'toggleAllPlaces'
		'click .checkin-place': 'addCheckin'
	
	initialize: ->
		@options.sidebar_filler = ap.me.attributes
		@options.sidebar = 'hub'
		@initRender()
		_.whenReady 'tpls', =>
			setTimeout =>
				@initBroadcasts()
			, 750
	rendered: ->
		@getLocation()
		if not ap.isDesktop
			$('#dispatch-shell').hide()
		setTimeout ->
			window.scrollTo(0, 1)
		, 1
		
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

	getLocation: (cb = false) ->
		navigator.geolocation.getCurrentPosition (pos) =>
			ap.location = pos
			if cb
				cb()
	showPlaceSelect: (e) ->
		e.preventDefault()
		$('#check-in-modal').show()
		$('#check-in-places').hide()
		$.scrollTo(0)
		if ap.location
			places = @placesByDistance(ap.location.coords)
			@renderPlacesByDistance(places)
		else
			@getLocation =>
				@showPlaceSelect(e)

	toggleAllPlaces: (e) ->
		el = $(e.currentTarget)
		if el.hasClass("showing-all")
			el.removeClass("showing-all").html('Show All Places')
			$('.checkin-place-far').css('display', 'none')
			$('footer').show()
		else
			el.addClass("showing-all").html('Hide Far Places')
			$('.checkin-place-far').css('display', 'block')
			$('footer').hide()

	renderPlacesByDistance: (places) ->
		html = '<h4>Where are you?</h4>'
		count = 0
		for place in places
			count += 1
			nearby_class = ' checkin-place-far'
			if (place.distance < 320 || count < 5)  && count < 5
				nearby_class = ' checkin-place-nearby'
			location_id = place.place_id
			location_type = "place"
			tk place.place_id
			html += '<a href="#" class="checkin-place'+nearby_class+'" data-location_type="'+location_type+'" data-location_id="'+location_id+'">
				<span class="checkin-place-name">'+place.name+'</span>
				<span class="checkin-place-addr">'+place.address.replace(', Portland, OR', '')+'
				<span class="checkin-place-distance">'+Math.ceil(place.distance)+' meters</span>
				</span>
			</a>'
		html += '<a href="#" id="checkin-toggle-all-places" class="button">Show All Places</a>'
		$('#check-in-places').html(html).show()
		$('#check-in-locating').hide()

	placesByDistance: (pos) ->
		sort = false
		placesByDist = []
		tmp = []
		places = @getPlaces()
		for place in places
			if pos
					dist = _.getDistance pos.latitude, pos.longitude, place.lat, place.lon
					tmp.push [dist, place]
					sort = true
			else
				tmp.push [0, place]
		if sort
			tmp.sort (a, b)->
				return a[0] - b[0]
		for p in tmp
			p[1].distance = p[0]
			placesByDist.push p[1]
		return placesByDist

	getPlaces: ->
		places = ap.places
		ap.Events.each ->

	addCheckin: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		location_type = el.data('location_type')
		location_id = el.data('location_id')
		el.html('<span class="checkin-status">Checking in...</span>')
		ap.api 'post user/checkin', {location_type: location_type, location_id:location_id}, (rsp) ->
		 	el.html('<span class="checkin-status">Checked in!</span>')
		 	setTimeout =>
		 		$('#check-in-modal').hide()
		 	, 750


	whenFinished: ->
		$(window).unbind('hashchange')
		tk ap.isMobile
		if not ap.isMobile
			$('#counter-shell').show()
		$('.settings-link').unbind()
		$('html').removeClass('attended-before')
