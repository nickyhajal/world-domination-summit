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

user = {};
ap.Views = {}
ap.Routes = {}

ap.init = () ->
	if ap.me
		$('html').addClass('is-logged-in')
	ap.initAssets()
	_.whenReady 'me', ->
		ap.initSearch()

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
			ap.me = new ap.User(rsp.me)
		_.isReady 'me'

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
