ap.Counter =
	init: ->
		@cnt = $('#counter-shell')
		@initEvents()
	initEvents: ->
		$(window).on('scroll', @scroll)
	scroll: ->
		cnt = $('#counter-shell')
		left = cnt.offset().left
		if window.scrollY > 271
			cnt.addClass('counter-fixed')
			cnt.css('left', left+'px')
		else
			cnt.removeClass('counter-fixed')
			cnt.css('left', '15px')
