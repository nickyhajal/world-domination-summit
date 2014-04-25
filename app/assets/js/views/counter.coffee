ap.Counter =
	init: ->
		@cnt = $('#counter-shell')
		@initEvents()
		@countdown()
	initEvents: ->
		$(window).on('scroll', @scroll)
	scroll: ->
		cnt = $('#counter-shell')
		side = $('#sidebar-shell')
		left = cnt.offset().left
		threshold = 271
		if not cnt.is(':visible')
			threshold = 305
		if window.scrollY > threshold
			cnt.addClass('counter-fixed')
			side.addClass('sidebar-fixed')
			cnt.css('left', left+'px')
		else
			cnt.removeClass('counter-fixed')
			side.removeClass('sidebar-fixed')
			cnt.css('left', '15px')
	countdown: ->
		now = new Date().getTime()
		end = new Date(2014,6,11).getTime()
		diff = (end - now) / 1000
		days = Math.floor(diff / 86400)
		hours = Math.floor((diff % 86400) / 3600)
		minutes = Math.floor(((diff % 86400) % 3600) / 60)
		$('#counter-days div').text(days)
		$('#counter-hours div').text(hours)
		$('#counter-mins div').text(minutes)
		setTimeout =>
			@countdown()
		, 60001
