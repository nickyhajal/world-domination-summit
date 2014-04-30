ap.initMobile = ->
	$('body')
	.on('click', '#nav-link-expand', ap.toggleNav)
	$(window).resize(ap.checkMobile)
ap.toggleNav = (force = false) ->
	nav = $('#nav-links')
	state = 'nav-links-open'
	if nav.hasClass(state) or (force and typeof force isnt 'object')
		nav.removeClass(state)
	else
		nav.addClass(state)

ap.checkMobile = ->
	width = $(window).outerWidth()
