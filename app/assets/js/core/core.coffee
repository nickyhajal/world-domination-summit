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
	ap.Counter.init()
	_.whenReady 'me', ->
		ap.initTemplates()
		ap.initRouter()

# Start with the 
ap.initMe = ->
	ap.api 'get me', {}, (rsp) ->
		if rsp.me
			ap.me = new ap.User(rsp.me)
		_.isReady 'me'
		
ap.initTemplates = ->
	ap.template_options = {}
	for name,html of ap.templates
		if html.indexOf('----tpl_opts----') > -1
			bits = html.split('----tpl_opts----')
			ap.template_options[name] = bits[0].replace(/(<([^>]+)>)/ig,"")
			ap.templates[name] = bits[1]
	for opt_name,opts of ap.template_options
		o = {}
		opts = opts.split('\n')
		for opt in opts
			if opt.length
				[name, val] = opt.split(':')
				o[_.trim(name)] = _.trim(val)
		ap.template_options[opt_name] = o

# Start up Backbone's router
ap.initRouter = ->
	ap.Router = new Router()
	Backbone.history.start({pushState: true})
	$('body').on 'click', "a[href=^'/']", (e) ->
		href = $(e.currentTarget).attr('href')

		# Catch clicks on links to use our navigate function instead
		# Skip if a super-key is being pushed
		if !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey
		    e.preventDefault()
		    url = href.replace(/^\//, '')
		    ap.Router.navigate url, {trigger: true}

# Navigate to a new URL using push-state
ap.navigate = (panel) ->
	ap.Router.navigate(ap.getPanelPath(panel), {trigger: true})

# Get
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

