###

	Mission Ops Page

###

ap.Views.hub = XView.extend
	location: false
	checkinTimo: 0
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
		if not ap.isDesktop
			$('#dispatch-shell').hide()
			@updateNotnCount()
		setTimeout ->
			window.scrollTo(0, 1)
		, 1
		$('#small-logo').on('click', @closePlaceSelect)
		_.whenReady 'assets', =>
			# @getCheckins()
			@startTour()

	startTour: ->
		if !+ap.me.get('tour') and ap.isDesktop
			ap.Modals.open('tour-start')
			$('#tour-start').on 'click', =>
				ap.Modals.close()
				intro = introJs()
				intro.onbeforechange (elm) =>
					step = $(elm).data('step')
					id = $(elm).attr('id')
					if id  == 'tour-end'
						ap.Modals.open('tour-end')
						setTimeout ->
							$.scrollTo(0)
							intro.exit()
							$('.introjs-helperNumberLayer').hide()
							$('.introjs-tooltip').hide()
							ap.api 'put user', {tour: '1', user_id: ap.me.get('user_id')}
						, 5
						return false
					else
						$('#top-nav,.dispatch-feed,#dispatch-shell').attr('style', '')
						if step is 1
							$('.dispatch-feed').attr('style', 'height:500px; overflow:hidden; margin-bottom:300px;')
							$('#dispatch-shell').attr('style', 'margin-left:-20px; padding-left:70px; padding-top:20px;')
						if step is 3
							$('#top-nav').attr('style', 'margin-bottom:-41px; position:relative;')
						$.scrollTo(0)
				intro.start()

	initBroadcasts: ->
		if +ap.me.get('tour')
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
	closePlaceSelect: (e) ->
		modal = $('#check-in-modal')
		if modal.is(':visible')
			e.preventDefault()
			e.stopPropagation()
			modal.hide()
			$('#checkin-x').off('click', @closePlaceSelect)
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
		html = '<a href="#" id="checkin-x">X</a><h4>Where are you?</h4>'
		count = 0
		for place in places
			count += 1
			nearby_class = ' checkin-place-far'
			if (place.distance < 320 || count < 5)  && count < 5
				nearby_class = ' checkin-place-nearby'
			location_id = place.place_id
			location_type = if place.type? then place.type else 'place'
			html += '<a href="#" class="checkin-place'+nearby_class+'" data-location_type="'+location_type+'" data-location_id="'+location_id+'">
				<span class="checkin-place-name">'+place.name+'</span>
				<span class="checkin-place-addr">'+place.address.replace(', Portland, OR', '')+'
				<span class="checkin-place-distance">'+Math.ceil(place.distance)+' meters</span>
				</span>
			</a>'
		html += '<a href="#" id="checkin-toggle-all-places" class="button">Show All Places</a>'
		$('#check-in-places').html(html).show()
		$('#checkin-x').on('click', @closePlaceSelect)
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
		places = JSON.parse(JSON.stringify(ap.places))
		added = []
		ap.Events.each (ev) ->
			time = moment.utc(ev.get('start'))
			day = time.format('dddd')
			time = +time.format('X')
			now = +(new Date()) / 1000

			if ap.env is 'development'
				tz_shift = 0
			else
				tz_shift = 7 * 3600
			begin = now - tz_shift - 14400
			end = now - tz_shift + 3600
			if time > begin and time < end
				if (ev.get('type') isnt 'program') or day is 'Thursday' or day is 'Friday'
					if added.indexOf ev.event_id is -1
						ev = ev.attributes
						ev.name = ev.what
						ev.place_id = ev.event_id
						ev.type = 'event'
						places.push ev
						added.push ev.event_id
		return places


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

	getCheckins: ->
		ap.api 'get checkins/recent', {}, (rsp) ->
			html = ''
			if rsp.checkins.length
				for place in rsp.checkins
					num_checkins = place.num_checkins
					type = place.location_type
					id = place.location_id
					if type is 'event'
						the_place = ap.Events.get(id).attributes
						name = the_place.what+'<span class="checkin-is-event">event</span>'
					else if type is 'place'
						for p in ap.places
							if +p.place_id is +id
								the_place = p
								name = the_place.name
								break
					address = the_place.address.replace(', Portland, OR', '')
					html += '<div class="checkin-result-row">
						<span class="checkin-result-name">'+name+'</span>
						<span class="checkin-result-checkins">'+num_checkins+'</span>
						<span class="checkin-result-address">'+address+'</span>
						</div>
						'
			else
				html = '<div id="checkin-empty" class="checkin-result-row">
						Check-in to your location above and get the party started!
					</div>
					'

			$('#happening-list').html(html)
		# @checkinTimo = setTimeout =>
		# 	# @getCheckins()
		# , 750




	whenFinished: ->
		$(window).unbind('hashchange')
		$('#small-logo').off('click', @closePlaceSelect)
		$('#checkin-x').off('click', @closePlaceSelect)
		clearTimeout(@checkinTimo)
		if not ap.isMobile
			$('#counter-shell').show()
		$('.settings-link').unbind()
		$('html').removeClass('attended-before')

	updateNotnCount: ->
		ap.api 'get user/notifications/unread', {}, (rsp) =>
			if rsp.notifications.length > 0
				$('.hub-notification-count').text(rsp.notifications.length)
				if ap.isPhone
					$('#hub-button-phone-notifications').css('padding', '20px 0').css('height', 'auto')
				if ap.isTablet
					shell = $('#hub-button-tablet-notifications').addClass('has_notifications')
					$('span', shell).html('Notifications')
					$('.hub-notification-count').css('display', 'inline')
