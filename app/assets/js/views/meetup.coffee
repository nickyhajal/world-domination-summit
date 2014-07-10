ap.Views.meetup = XView.extend
	atnTimo: 0
	events: 
		'click .meetup-attendees-toggle': 'toggle_attendees'

	initialize: ->

		_.whenReady 'assets', =>
			@options.meetup = ap.Events.getBySlug(@options.meetup)
			@options.out = _.template @options.out, @options.meetup.attributes
			@options.sidebar = 'meetup'
			@options.sidebar_filler = @options.meetup.attributes
			@initRender()

	sidebarRendered: ->
		ev = @options.meetup
		maxed = false
		if ev.get('num_rsvps')? and ev.get('num_rsvps') > ev.get('max')
			maxed = true
		if maxed
			$('.rsvp-button', '#sidebar').attr('data-maxed', 'true')
			tk $('.rsvp-button', '#sidebar')

	rendered: ->
		@renderMap()
		_.whenReady 'users', =>
			@renderHosts()
			@renderAttendees()

	renderMap: ->
		_.whenReady 'googlemaps', =>
			attendee = @options.meetup.attributes
			profile_map_el = document.getElementById('meetup-profile-map')
			latlon = new google.maps.LatLng(attendee.lat, attendee.lon)
			mapOptions = 
				center: latlon
				zoom: 16
				scrollwheel: false
				disableDefaultUI: true
			profile_map = new google.maps.Map(profile_map_el, mapOptions)
			marker = new google.maps.Marker
      position: latlon
      map: profile_map
      title: 'Your Meetup\'s Venue'

	renderHosts: ->
		html = ''
		for host in @options.meetup.attributes.hosts
			host = ap.Users.get(host)
			if host
				html += '
					<div class="meetup-hosted-by">Hosted by</div>
					<div class="meetup-host-shell">
						<div class="meetup-host-avatar" style="background:url('+host.get('pic')+')"></div>
						<div class="meetup-host-name">'+host.get('first_name')+' '+host.get('last_name')+'</div>
					</div>
				'
		$('.meetup-hosts', $(@el)).html(html)

	renderAttendees: ->
		clearTimeout(@atnTimo)
		ap.api 'get event/attendees', {event_id: @options.meetup.get('event_id')}, (rsp) =>
			if rsp.attendees?.length > 1
				html = '
				<div class="line-canvas"></div>
				<h3>'+rsp.attendees.length+' WDSers Are Attending</h3>
				<div id="meetup-attendees-shell">
				'
				noPic = []
				for atn in rsp.attendees
					atn = ap.Users.get(atn)
					if atn? and atn.get('pic') isnt '/images/default-avatar.png'
						html += '<div class="meetup-attendee">
							<div class="meetup-attendee-avatar" style="background:url('+atn.get('pic')+')"></div>
							<div class="meetup-attendee-name">'+atn.get('first_name')+'<br>'+atn.get('last_name')+'</div>
						</div>'
					else if atn?
					 	noPic.push atn
				for atn in noPic
					html += '<div class="meetup-attendee">
						<div class="meetup-attendee-avatar" style="background:url('+atn.get('pic')+')"></div>
						<div class="meetup-attendee-name">'+atn.get('first_name')+'<br>'+atn.get('last_name')+'</div>
					</div>'
				html += '</div>'

				toggle_class = 'meetup-attendees-closed'
				link_text = 'Show All Attendees'
				if $('.meetup-attendees-opened').length
					toggle_class = 'meetup-attendees-opened'
					link_text = 'Show Less Attendees'
				$('#meetup-attendees').html(html)
				$m = $('#meetup-attendees-shell')
				if $m.height() > '180'
					$m.css('max-height', '154px')
					.append('<a href="#" class="meetup-attendees-toggle">'+link_text+'</a>')
					.addClass(toggle_class)
		@atnTimo = setTimeout =>
			@renderAttendees()
		, 30000

	toggle_attendees: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		$m = $('#meetup-attendees-shell', $(@el))
		$a = $('.meetup-attendees-toggle', $(@el))
		if $m.hasClass('meetup-attendees-closed')
			$m.addClass('meetup-attendees-opened')
			.removeClass('meetup-attendees-closed')
			$a
			.html('Show Less Attendees')
		else
			$m.removeClass('meetup-attendees-opened')
			.addClass('meetup-attendees-closed')
			$a
			.html('Show All Attendees')

	whenFinished: ->
		clearTimeout(@atnTimo)
