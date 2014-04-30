ap.initMobile = ->
	$('body')
	.on('click', '#nav-link-expand', ap.toggleNav)
	$(window).resize(ap.checkMobile)
ap.toggleNav = (force = false) ->
	nav = $('#nav-links')
	state = 'nav-links-open'
	if (typeof force is 'object')
		force.preventDefault()
	if nav.hasClass(state) or (force and typeof force isnt 'object')
		nav.removeClass(state)
	else
		nav.addClass(state)

ap.checkMobile = ->
	width = $(window).outerWidth()
	if width <= 768
		$wall = $('#waterfall')
		$video = $('#video')
		scale = width/990
		$video.css('height', (width*(9/16)+'px'))
		$wall.css
			'transform': 'scale('+scale+')'
