ap.Views.meetups = XView.extend
	saveScrollPosition: true
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
		maxed_html = ''
		sidebar_html = ''
		ap.Events.each (ev) =>
			if ev.get('type') is 'meetup'
				maxed = false
				if ev.get('num_rsvps')? and ev.get('num_rsvps') > ev.get('max')
					maxed = true
				maxed_class = if maxed then ' meetup-maxed' else ''
				time = moment.utc(ev.get('start'))
				day = time.format('MMMM Do')
				if day isnt lastDay
					lastDay = day
					daylink = _.slugify(day)
					html += maxed_html
					html += '<a href="#" name="'+daylink+'"></a>'
					html += '<h3>'+day+'</h3>'
					maxed_html = ''
					sidebar_html += '<a href="#'+daylink+'">'+day+'</a>'
				hosts = @renderHosts(ev)

				if maxed
					button_maxed = ' data-maxed="true"'
				event_button = '<a href="#"'+button_maxed+' data-event_id="'+ev.get('event_id')+'" data-start="RSVP" data-cancel="unRSVP" class="rsvp-button">RSVP</a>'
				event_html = '
					<div class="meetup-descr-shell'+maxed_class+'">
						<div class="meetup-sidebar">
							<div class="meetup-time">'+time.format('h:mm a')+'</div>
							<div class="meetup-host">'+hosts+'</div>
							' + event_button + '
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
				if maxed
					maxed_html += event_html
				else
					html += event_html
		html += maxed_html
		$('#meetup-list').html(html).scan()
		$('#meetup-sidebar').html(sidebar_html)

	renderEvent: (ev) ->

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