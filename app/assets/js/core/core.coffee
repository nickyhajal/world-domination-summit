###

Initializes the client-side of the WDS site

Includes anything that happens before routing
and extremely broad tasks (like calling the api)

###

window.tk = (data)->
	if console
		console.info(data)
$ = jQuery
$('html').addClass('jsOn')
$ ->
	ap.init();

user = {};
ap.Views = {}
ap.Routes = {}

ap.init = () ->
	if ap.me
		$('html').addClass('is-logged-in')
	ap.initAssets()
	ap.initMobile()
	ap.Counter.init()
	ap.initTemplates()
	ap.initRouter()
	_.whenReady 'me', ->
		ap.initSearch()
	ap.Modals.init()

ap.accoms = [
	{id: 'paramount', text: 'Paramount Hotel'},
	{id: 'deluxe', text: 'Hotel deLuxe'},
	{id: 'lucia', text: 'Hotel Lucia'},
	{id: 'sentinel', text: 'Sentinel Hotel'},
	{id: 'modera', text: 'Hotel Modera'},
	{id: 'other', text: 'Another hotel'},
	{id: 'hostel', text: 'Hostel'},
	{id: 'airbnb', text: 'AirBnb or Similar'},
	{id: 'friend', text: 'Staying with a friend'},
	{id: 'local', text: 'I\'m local!'},
	{id: 'not-sure', text:'I\'m not sure yet (but I\'ll book soon!)'}
]

ap.allUsers = {}

ap.onResizes = {}
$(window).resize ->
	for id,fnc of ap.onResizes
		fnc()

ap.bindResize = (id, fnc) ->
	ap.onResizes[id] = fnc

ap.unbindResize = (id) ->
	delete ap.onResizes[id]


###

 Get assets, cache in localStorage and update when necessary

###

ap.update = {}
ap.initAssets = ->
	assets = ['all_attendees','me','events', 'tpls', 'interests', 'speakers', 'ranks', 'tasks', 'achievements', 'places']
	ap.getAssets(assets)
ap.getAssets = (assets) ->
	tracker = ap.get('tracker')
	ap.api 'get assets', {tracker: tracker, assets: assets.join(',')}, (rsp) ->
		for asset in assets
			ready = true
			if rsp[asset]?
				if asset isnt 'me'
					ap[asset] = rsp[asset]
					ap.put(asset, rsp[asset])
					ap.track(asset)
				else
					ap.asset_me = rsp[asset]
			else
				ap[asset] = ap.get(asset)

			if ap.update[asset]?
				ready = ap.update[asset]()
			if ready
				_.nowReady asset

		_.nowReady('assets')

ap.track = (asset, updated = false) ->
	tracker = ap.get('tracker')
	tracker[asset] = Math.floor((+(new Date())) / 1000)
	ap.put('tracker', tracker)

ap.update.all_attendees = ->
	setTimeout ->
		ap.Users.add(ap.all_attendees)
		_.nowReady 'users'
	, 200
	return false

ap.update.me = ->
	if ap.asset_me
		ap.login ap.asset_me
	return true

ap.update.tpls = ->
	ap.templates = ap.tpls
	ap.initTemplates()
	return true

ap.update.ranks = ->
	_.whenReady 'me', =>
		if ap.me and ap.me.setRank?
			ap.me.setRank()
			_.isReady 'ranks'

ap.update.tpls = ->
	ap.templates = ap.tpls
	ap.initTemplates()
	return true

###
	Process templates for template optiosn
###
ap.initTemplates = ->
	for name,html of ap.templates
		ap.processTemplate(name, html)

ap.processTemplate = (name, html) ->
	unless ap.template_options?
		ap.template_options = {}

	if html.indexOf('----tpl_opts----') > -1
		bits = html.split('----tpl_opts----')
		if bits.length > 1
			ap.template_options[name] = bits[0].replace(/(<([^>]+)>)/ig,"")
			content = bits[1].replace(/\`script/g, '<script')
			content = content.replace(/`\/script/g, '</script')
			ap.templates[name] = content
			opts = ap.template_options[name].split('\n')
			o = {}
			for opt in opts
				if opt.length
					bits = opt.split(':')
					part = bits[0]
					val = bits.splice(1).join(':')
					o[_.trim(part)] = _.trim(val)
			ap.template_options[name] = o
	else
		ap.template_options[name] = {}
		ap.templates[name] = html



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

		if href?
			if href.indexOf('#') > -1 and href isnt '#'
				anchor = $('a[name="'+href.replace('#', '')+'"]')
				if anchor.length
					top = anchor.offset().top - 100
					$.scrollTo top, 150,
						axis: 'y'
					e.preventDefault()

			else if href is ':ignore' || href.indexOf('javascript:void') > -1
				e.preventDefault()

			# Catch clicks on links to use our navigate function instead
			# Skip if a super-key is being pushed
			else if href isnt '#' and link.attr('target') isnt '_blank' and !e.altKey and !e.ctrlKey and !e.metaKey and !e.shiftKey and href.indexOf('http') != 0 and href.indexOf('/api/') < 0
			    e.preventDefault()
			    url = href.replace(/^\//, '')
			    ap.Router.navigate url, {trigger: true}

ap.loading = (setLoading = false) ->
	if setLoading
		unless $('#loading-logo').length
			html = '
			<div id="loading-logo">
			</div>
			'
			$('body').append(html)
	else
		$('#loading-logo').remove()

ap.initSearch = ->
	_.whenReady 'users', ->
		$('body')
		.on 'keyup', '.search-input', ->
			val = $(this).val()
			shell = $(this).closest('.search-shell')
			friend = shell.data('friend')?
			if val.length > 2
				results = ap.Users.search(val)
				html = ''
				for result in results
					name = result.get('first_name')+' '+result.get('last_name')
					if friend and ap.isPhone
						name = _.truncate(name, 14)
					html += '<a class="result-link" href="/~'+result.get('user_name')+'">
						<span style="background:url('+result.get('pic')+')"></span>
					'+name
					if friend
						format = ''
						if ap.isPhone
							format = ' data-format="short"'
						html += '<div class="follow-button"'+format+' data-user_id="'+result.get('user_id')+'"></div>'
					html += '</a>'
				$('.search-results', shell).html(html).scan()
				if ap.isMobile
					$('#primary-links').hide()
			else if val.length is 0
				x = 'empty state'

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
