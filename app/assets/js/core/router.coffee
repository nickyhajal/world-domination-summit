window.Router = Backbone.Router.extend
	routes:
		"signup/:": "signup"
		"join-duo/:hash": "joinDuo"
		"duo/:hash": "duo"
		"invite/:hash": "invite"
		"*actions": "defaultRoute"
	before: ->
	defaultRoute: (actions) ->
		# If no action, figure it out
		if (actions is '')
			if (ap.authd)
				actions = 'home';
			else
				actions = 'login';
		ap.goTo(actions)

	joinDuo: (hash) ->
		if ap.me
			ap.loading()
			ap.api 'get duo', {hash: hash}, (rsp) ->
				ap.goTo 'join',
					duo: new ap.Duo(rsp.duo)
					hash: hash

	duo: (hash) ->
		if ap.me
			ap.loading()
			ap.api 'get duo', {hash: hash, inc_entries: true}, (rsp) ->
				ap.goTo 'duo', 
					duo: new ap.Duo(rsp.duo)
		else
			ap.navigate 'login'

	invite: (hash) ->
		if ap.me
			ap.loading()
			ap.Duos.getOrFetch {hash: hash}, (duo) ->
				ap.goTo 'invite',
					duo: duo
		else
			ap.navigate 'login'

	###
	 Profile Contoller
	###
	goToProfile: (id) ->
		ap.onUser = id
		if ap.onPanel?
			ap.scrollPos[ap.onPanel] = $(window).scrollTop()
		ap.users[id].renderProfile('#userProfile-content')
		$.scrollTo(0)
		ap.goTo()
	logout: ->
		ap.nav 'login'
		_.a 'logout', {}, (rsp) ->
		localStorage.clear()
		@stop

###
Show Loading
###
ap.initd = false
ap.loadingTimos = []
ap.loading = ->
	ap.loadingTimos.push setTimeout ->
		ap.goTo 'loading'
	, 50
ap.nav = (uri) ->
	Backbone.history.navigate uri, {trigger: true}

ap.goTo = (panel = '', options = {}) ->
	# Go to the panel
	if panel isnt 'loading'
		for timo in ap.loadingTimos
			clearTimeout(timo)
	panel = if panel and panel.length then panel else 'home'
	$s = $('#')
	if ap.initd
		$('#content_shell').css('opacity', '0')
	else
		ap.initd = true
	ap.onPanel = panel
	if ap.Views[panel]?
		if ap.currentView?
			ap.currentView.unbind()
			ap.currentView.undelegateEvents()
		$('#content_shell').attr('class', '')
		options.el = $('#content_shell')
		options.out = ap.templates['pages_'+panel] + '<div class="clear"></div>'
		options.render = 'replace'
		options.onRender = ->
			$('#content_shell').css('opacity', '1')
		setTimeout ->
			ap.currentView = new ap.Views[panel] options
		, 120

ap.back = ->
	history.go(-1);
	return false;