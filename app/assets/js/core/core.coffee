window.tk = (data)->
	if console
		console.log(data)
$ = jQuery
$('html').addClass('jsOn')
$ ->
	ap.init();
	butter.init()

user = {};
ap.Views = {}
ap.init = () ->
	ap.initMe()
	_.whenReady 'me', ->
		ap.initRouter()

ap.initMe = ->
	ap.api 'get me', {}, (rsp) ->
		if rsp.me
			ap.me = new ap.User(rsp.me)
		_.isReady 'me'
ap.initRouter = ->
	ap.Router = new Router()
	Backbone.history.start({pushState: true})
	$('body').on 'click', "a[href=^'/']", (e) ->
		href = $(e.currentTarget).attr('href')
		if !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey
		    e.preventDefault()
		    url = href.replace(/^\//, '')
		    ap.Router.navigate url, {trigger: true}

ap.navigate = (panel) ->
	ap.Router.navigate(ap.getPanelPath(panel), {trigger: true})

ap.getPanelPath = (panel)->
	map = 
		home: ''
	if map[panel]?
		path = map[panel]
	else
		path = panel

	return '/'+path

ap.api = (url, data, success = false, error = false, opts = {}) ->
	bits = url.split(' ')
	url = '/api/' + bits[1]
	opts.data = data
	opts.type = bits[0]
	if success
		opts.success = success
	if error
		opts.error = error
	$.ajax url, opts


###
 ASSET HANDLING
###
window.get = (i) ->
	if localStorage[i]?
		return JSON.parse localStorage[i]
	else
		{}
window.put = (i, v) ->
	localStorage[i] = JSON.stringify v

ap.splash = (checkin) ->

