window.Router = Backbone.Router.extend
	routes:
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
		$('body').attr('id', 'page-'+panel)

ap.back = ->
	history.go(-1);
	return false;