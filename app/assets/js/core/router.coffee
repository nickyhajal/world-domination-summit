###
 The Router and routes are defined here
 the functions that handle routes are in
 /app/assets/js/routes
###
ap.createRouter = ->
	window.Router = Backbone.Router.extend
		routes:
			"*actions": "defaultRoute"
			"logout": "logout"
		before: ap.Routes.before
		defaultRoute: ap.Routes.defaultRoute
		logout: ap.Routes.logout


###
 The following functions are vital
 to the routing process
###

###
# Show Loading
###
ap.loadingTimos = []
ap.loading = ->
	ap.loadingTimos.push setTimeout ->
		ap.goTo 'loading'
	, 50

###
#  Change the URL and trigger a page change
###
ap.nav = (uri) ->
	Backbone.history.navigate uri, {trigger: true}

###
# This re-renders the page to show new content
###
ap.goTo = (panel = '', options = {}) ->
	# Go to the panel
	if panel isnt 'loading'
		for timo in ap.loadingTimos
			clearTimeout(timo)
	panel = if panel and panel.length then _.trim(panel, '/') else 'home'
	$s = $('#')
	ap.onPanel = panel
	view = ap.Views[panel] ? ap.Views.default
	if ap.currentView?
		ap.currentView.unbind()
		ap.currentView.undelegateEvents()
	$('#content_shell').attr('class', '')
	options.el = $('#content_shell')
	if ap.templates['pages_'+panel]?
		tpl = 'pages_'+panel
	else
		tpl = 'pages_404'
	options.out = ap.templates[tpl] + '<div class="clear"></div>'
	options.render = 'replace'
	options.view = panel
	setTimeout ->
		$('body').attr('id', 'page-'+panel)
		ap.currentView = new view options
		$.scrollTo 0
	, 120

ap.back = ->
	history.go(-1);
	return false;