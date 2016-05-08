###

	The Router and routes are defined here
	the functions that handle routes are in
	/app/assets/js/routes

###

###
	Create the router
###
ap.scrollPos = {}
ap.createRouter = ->
	window.Router = Backbone.Router.extend
		protect: [
			'hub', 'welcome', 'settings', 'propose-a-meetup', 'communities',
			'your-schedule', 'meetups', 'your-schedule', 'race', 'transfer'
		]
		initialize: ->
			$('#back-button').click(ap.back)
			@route("*actions", 'default', ap.Routes.defaultRoute)
			@route(/^[0-9a-z]{40}$/, 'hash', ap.Routes.hashLogin)
			@route("logout", 'logout', ap.Routes.logout)
			@route("reset-password/:hash", 'reset', ap.Routes.reset)
			@route("transfer/:hash", 'transfer', ap.Routes.hashLogin)
			@route("academies/:hash", 'academies', ap.Routes.hashLogin)
			@route("community/:community", 'community', ap.Routes.community)
			@route("academy/:academy", 'academy', ap.Routes.academy)
			@route("dispatch/:feed_id", 'dispatch', ap.Routes.dispatch)
			@route("task/:task_slug", 'task', ap.Routes.task)
			@route("notes/:user_id", 'notes', ap.Routes.notes)
			@route("meetup/:meetup", 'meetup', ap.Routes.meetup)
			@route("your-transfer/:transfer_id", 'reset', ap.Routes.your_transfer)
			@route("mission-accomplished/:ticket_hash", 'mission_accomplished', ap.Routes.mission_accomplished)
			@route("send-ticket/:ticket_hash", 'send_accomplished', ap.Routes.send_ticket)
			@route("claim-ticket/:ticket_hash", 'claim_accomplished', ap.Routes.claim_ticket)
			@route("admin/:panel", 'admin', ap.Routes.admin)
			@route("admin/:panel/:extra", 'admin', ap.Routes.admin)
			@route("hub", 'hub', ap.Routes.hub)
			@route("logout", 'logout', ap.Routes.logout)
			@route(/^~(.)+/, 'profile', ap.Routes.profile)
		before: ap.Routes.before


###--

	The following functions are vital
	to the routing process

--###

###
	Show Loading
###
# ap.loading = (fade = false) ->
# 	content = $('#page_content')
# 	loading = $('#loading')
# 	loading
# 		.css
# 			left: content.offset().left+'px'
# 			top: content.offset().top+'px'
# 			width: content.width()+'px'
# 			height: content.height()+'px'
# 	if fade
# 		loading.addClass('loading-faded')
# 	loading.addClass('is-loading')

ap.loaded = ->
	$('#loading').attr('class', '')

###
	Check if a user is logged in
	Obviously not very secure but real protection
	happens server-side to be sure a logged-out user
	can't get or save anything protected
###
ap.protect = ->
	return ap.me? and ap.me


ap.login = (me) ->
	if me
		$('html').addClass('is-logged-in')
		$('#small-logo,#logo').attr('href', '/hub')
		ap.me = new ap.User(me)

ap.logout = ->
	$('html').removeClass('is-logged-in')
	$('#small-logo,#logo').attr('href', '/')
	ap.api 'post user/logout'
	localStorage.clear()
	ap.me = false

###
	Navigate to a new URL using push-state
###
ap.navigate = (panel) ->
	ap.Router.navigate(ap.getPanelPath(panel), {trigger: true})

ap.getPanelPath = (panel) ->
	map =
		home: ''
	return '/' + (map[panel] ? panel)

ap.syncNav = (panel) ->
	$('.nav-link-active').removeClass('nav-link-active')
	$('#nav-'+panel).addClass('nav-link-active')
	ap.toggleNav(true)

###
	Re-render the page to show new content
###
ap.goTo = (panel = '', options = {}, cb = false) ->
	# Go to the panel
	ap.Modals.close()
	if panel.indexOf('admin_') > -1
		$('body').addClass('is-admin')
	else
		$('body').removeClass('is-admin')
	panel = if panel and panel.length then _.trim(panel, '/') else 'home'
	$s = $('#')
	ap.onPanel = panel
	view = ap.Views[panel.replace(/\-/g, '_')] ? ap.Views.default
	render = []
	getTpl = ->
		# Unbind current view
		if ap.currentView?
			$('.dispatch-feed')?.data('feed')?.stop()
			ap.currentView.unbind()
			ap.currentView.undelegateEvents()

		# Reset Shell
		$('#content_shell').attr('class', '')
		options.el = $('#content_shell')

		# Get the template
		tpl = 'pages_'+panel
		if ap.templates['pages_'+panel]?
			tpl = 'pages_'+panel
			render(tpl)
		else
			ap.api 'get tpl', {tpl: panel}, (rsp) ->
				if rsp.tpl?
					ap.processTemplate(tpl, rsp.tpl)
					render(tpl)
				else
					render('pages_404')

	render = (tpl)->
		# Setup the template
		options.out = ap.templates[tpl] + '<div class="clear"></div>'
		options.render = 'replace'
		options.view = panel
		setTimeout ->
			if panel is 'home'
				$('#logo-waves').hide()
			else
				$('#logo-waves').show()
			$('body').attr('id', 'page-'+panel)
			if ap.currentView? and ap.currentView
				ap.currentView.finish()
			ap.currentView = new view options
			if ap.scrollPos?[panel]?
				scrollTo = ap.scrollPos[panel]
			else
				scrollTo = 0
			$.scrollTo scrollTo
			ap.syncNav(panel)
			ap.checkMobile()
			if cb
				cb()
		, 60
		history_length = history.length
		if history_length > 1
			$('#back-button').show()
		else
			$('#back-button').hide()
	getTpl()

ap.back = ->
	history.go(-1);
	return false;