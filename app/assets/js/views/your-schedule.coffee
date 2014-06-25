ap.Views.your_schedule = XView.extend
	initialize: ->
		@options.sidebar = 'hub'
		@initRender()

	rendered: ->
		_.whenReady 'events', =>
			_.whenReady 'users', =>
				@renderEvents()

	renderEvents: ->
		lastDay = ''
		html = ''
		tk 'hey'
		ap.Events.each (ev) =>
			if ap.me and ap.me.isAttendingEvent(ev)
				time = moment.utc(ev.get('start'))
				day = time.format('MMMM Do')
				if day isnt lastDay
					lastDay = day
					html += '<h3>'+day+'</h3>'
				hosts = @renderHosts(ev)
				note = @renderNote(ev)
				event = 
					time: time.format('h:mm a')
					hosts: hosts
					event_id: ev.get('event_id')
					slug: _.slugify(ev.get('what'))
					what: ev.get('what')
					note: note
					place: ev.get('place')
					directions_link: 'http://maps.google.com?q='+encodeURI(ev.get('address'))

				html += _.t 'parts_schedule-row', event

		$('#attendee-schedule').html(html).scan()

	renderNote: (ev) ->
		html = ''
		if ev.get('note')?.length
			html = '<div class="schedule-note">'+ev.get('note')+'</div>'
		return html

	renderHosts: (ev) ->
		html = ''
		for host in ev.get('hosts')
			host = ap.Users.get(host)
			if host
				html += '
					<div class="schedule-host-shell">
						<div class="schedule-host-avatar" style="background:url('+host.get('pic')+')"></div>
						<a href="/~"'+host.get('user_name')+'" class="schedule-host-name">'+host.get('first_name')+' '+host.get('last_name')+'</a>
					</div>
				'
		return html
