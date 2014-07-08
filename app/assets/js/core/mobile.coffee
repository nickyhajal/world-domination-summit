ap.initMobile = ->
	$('body')
	.on('click', '#nav-link-expand', ap.toggleNav)
	ap.checkMobile()
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
	$wall = $('#waterfall')
	$video = $('#video')
	ap.isDesktop = false
	if width < 1006 and width > 690
		ap.isTablet = ap.isMobile = true
		ap.isPhone = false
	else if width < 690
		ap.isPhone = ap.isMobile = true
		ap.isTablet = false
	else
		ap.isDesktop = true
		ap.isPhone = ap.isTablet = ap.isMobile = false

	if ap.isMobile
		$('body').addClass('is-mobile')
		$video.css('height', (width*(9/16)+'px'))
		header = $('#page-home #content_shell #header-title')
		search = $('#nav-search')
		if header
			header.remove()
			$('#logo').after(header)
		if search
			search.remove()
			$('#nav-links').prepend(search)
	else
		$('body').removeClass('is-mobile')
		header = $('#page-home #main-header #header-title')
		search = $('#nav-search')
		if header
			header.remove()
			$('#content_shell').prepend(header)
		if search
			search.remove()
			$('#nav-links').append(search)

	if ap.currentView?
		view = ap.currentView
		if ap.isTablet and view.tablet?
			view.tablet()

		if ap.isMobile and view.mobile?
			view.mobile()

		if ap.isPhone and view.phone?
			view.phone()

		if ap.isDesktop and view.desktop?
			view.desktop()