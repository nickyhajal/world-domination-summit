###

Initializes the client-side of the WDS site

Includes anything that happens before routing
and extremely broad tasks (like calling the api)

###

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
ap.Routes = {}

ap.init = () ->
	if ap.me
		$('html').addClass('is-logged-in')
	ap.initAssets()
	ap.initMobile()
	ap.Counter.init()
	_.whenReady 'me', ->
		ap.initTemplates()
		ap.initRouter()
		ap.initSearch()
	ap.Modals.init()

ap.allUsers = {}
ap.initAssets = ->
	assets = 'all_attendees,me'
	ap.api 'get assets', {assets: assets}, (rsp) ->
		if rsp.all_attendees
			setTimeout ->
				ap.Users.add(rsp.all_attendees)
				_.isReady 'users'
			, 500

		if rsp.me
			ap.login rsp.me
		_.isReady 'me'

###
	Process templates for template optiosn
###
ap.initTemplates = ->
	ap.template_options = {}
	for name,html of ap.templates
		if html.indexOf('----tpl_opts----') > -1
			bits = html.split('----tpl_opts----')
			if bits.length > 1
				ap.template_options[name] = bits[0].replace(/(<([^>]+)>)/ig,"")
				content = bits[1].replace(/\`script/g, '<script')
				content = content.replace(/`\/script/g, '</script')
				ap.templates[name] = content
			else
				ap.template_options[name] = {}
				ap.templates[name] = html
	for opt_name,opts of ap.template_options
		o = {}
		opts = opts.split('\n')
		for opt in opts
			if opt.length
				bits = opt.split(':')
				name = bits[0]
				val = bits.splice(1).join(':')
				o[_.trim(name)] = _.trim(val)
		ap.template_options[opt_name] = o

###
	Start up Backbone's router
###
ap.initRouter = ->
	ap.createRouter()
	ap.Router = new Router()
	Backbone.history.start({pushState: true})

	$('body').on 'click', ".back", ap.back
	$('body').on 'click', "a[href=^'/']", (e) ->
		link = $(e.currentTarget)
		href = link.attr('href')

		if href.indexOf('#') > -1
			anchor = $('a[name="'+href.replace('#', '')+'"]')
			if anchor.length
				top = anchor.offset().top - 100
				$.scrollTo top, 150, 
					axis: 'y'
				e.preventDefault()


		# Catch clicks on links to use our navigate function instead
		# Skip if a super-key is being pushed
		else if link.attr('target') isnt '_blank' and !e.altKey and !e.ctrlKey and !e.metaKey and !e.shiftKey and href.indexOf('http') != 0 and href.indexOf('/api/') < 0
		    e.preventDefault()
		    url = href.replace(/^\//, '')
		    ap.Router.navigate url, {trigger: true}

ap.initSearch = ->
	_.whenReady 'users', ->
		$('body')
		.on 'keyup', '.search-input', ->
			val = $(this).val()
			if val.length > 2
				results = ap.Users.search(val)
				html = ''
				for result in results
					html += '<a class="result-link" href="/~'+result.get('user_name')+'">
						<span style="background:url('+result.get('pic')+')"></span>
					'+result.get('first_name')+' '+result.get('last_name')+'</a>'
				$('.search-results').html(html)

###
	Make an api call
	the URL should start with the HTTP method followed by a space
	ex: 'post user/login'
	ex: 'get featured_content'
###
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

ap.get = (i) ->
	if localStorage[i]?
		return JSON.parse localStorage[i]
	else
		{}
ap.put = (i, v) ->
	localStorage[i] = JSON.stringify v
