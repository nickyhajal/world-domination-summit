ap.Views.meetups = XView.extend
	initialize: ->
		@options.sidebar = 'meetups'
		@initRender()

	rendered: ->
		_.whenReady 'events', =>
			_.whenReady 'users', =>
				@renderEvents()

	renderEvents: ->
		lastDay = ''
		html = ''
		ap.Events.each (ev) =>
			if ev.get('type') is 'meetup'
				time = moment.utc(ev.get('start')).subtract('hours', '7')
				day = time.format('MMMM Do')
				if day isnt lastDay
					lastDay = day
					html += '<h3>'+day+'</h3>'
				hosts = @renderHosts(ev)
				html += '
					<div class="meetup-descr-shell">
						<div class="meetup-sidebar">
							<div class="meetup-time">'+time.format('h:mm a')+'</div>
							<div class="meetup-host">'+hosts+'</div>
							<a href="#" data-event_id="'+ev.get('event_id')+'" data-start="RSVP" data-cancel="unRSVP" class="rsvp-button">RSVP</a>
							<a href="/meetup/'+_.slugify(ev.get('what'))+'">More Details</a>
						</div>
						<div class="meetup-content">
							<div class="meetup-name">'+ev.get('what')+'</div>
							<div class="meetup-descr-who">A meetup for '+ev.get('who')+'</div>
							<div class="meetup-descr">'+_.truncate(ev.get('descr'), 340)+'</div>
						</div>
					</div>
					<div class="clear"></div>
				'
		$('#meetup-list').html(html).scan()

	renderHosts: (ev) ->
		html = ''
		for host in ev.get('hosts')
			host = ap.Users.get(host)
			if host
				html += '
					<div class="meetup-descr-host-shell">
						<div class="meetup-descr-host-avatar" style="background:url('+host.get('pic')+')"></div>
						<div class="meetup-descr-host-name">'+host.get('first_name')+' '+host.get('last_name')+'</div>
					</div>
				'
		return html

	whenFinished: ->
		ap.scrollPos['meetups'] = window.scrollY
