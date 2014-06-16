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
	$('body').on('click', '.register-button', ap.register_click)


ap.allUsers = {}
ap.initAssets = ->
	ap.register_sync()
	assets = 'all_attendees,me'
	ap.api 'get assets', {assets: assets}, (rsp) ->
		if rsp.all_attendees
			setTimeout ->
				ap.Users.add(rsp.all_attendees)
			_.isReady 'users'
			, 500
		if rsp.me
			ap.me = new ap.User(rsp.me)
		ap.poll()
		_.isReady 'me'

ap.localizeRegistrations = (regs) ->
	ap.registrations = regs
	for id,reg of ap.get('registrations')
		ap.registrations[reg.user_id] = 1

ap.initSearch = ->
	_.whenReady 'users', ->
		$('body')
		.on 'keyup', '#register_search', ->
			val = $(this).val()
			if val.length > 1
				results = ap.Users.search(val)
				html = ''
				for result in results
					if ap.registrations[result.get('user_id')]
						str = 'Unregister'
					else
						str = 'Register'
					html += '
						<div class="search-row" href="/~'+result.get('user_name')+'">
							<span style="background:url('+result.get('pic')+')"></span>
						'+result.get('first_name')+' '+result.get('last_name')+'
						<a href="#" data-user_id="'+result.get('user_id')+'" class="register-button">'+str+'</a>
						<div class="location">'+result.get('location')+'</div>
						</div>
					'
				$('#search-results').html(html).show()
				$('#search_start').hide()
			else
				$('#search-results').hide()
				$('#search_start').show()

ap.poll = ->
	now = (new Date()).getTime()
	if ((now - ap.last_reg_sync) > 60000) && navigator.onLine
		x =1
		ap.register_sync()
	ap.registration_stats()
	setTimeout ->
		ap.poll()
	, 1000
	$('#search_start table').fadeIn()

ap.last_reg_sync = (new Date()).getTime()
ap.registration_stats = ->
	now = (new Date()).getTime()
	hourago = now -  3600000
	registrations = ap.get 'registrations'
	changes = ap.get 'changes'
	dev_hour = 0
	dev_all = 0
	unsynced = 0
	total_all = -1
	total_hour = -1
	if ap.total_all? and ap.total_hour?
		total_all = ap.total_all
		total_hour = ap.total_hour

	for i,reg of registrations
		if reg.date > hourago
			dev_hour += 1
		dev_all += 1
	for j,change of changes
		unsynced += 1

	if navigator.onLine
		$('#next_sync').html Math.floor((60000 - (now-ap.last_reg_sync))/1000)
	else
		$('#next_sync').html 'Offline'
	$('#device_reg_hour').html dev_hour
	$('#device_reg_all').html dev_all
	$('#unsynced').html unsynced
	if total_all > -1 and total_hour > -1
		$('#total_reg_hour').html total_hour
		$('#total_reg_all').html total_all

ap.register_click = (e) ->
	e.preventDefault()
	el = $(e.currentTarget)
	user_id = el.data('user_id')
	if ap.registrations[user_id]?
		action = 'unregister'
		el.html('Register')
		delete ap.registrations[user_id]
	else
		action = 'register'
		el.html('Unregister')
		ap.registrations[user_id] = '1'
	ap.register(user_id, action)

ap.register = (user_id, action) ->
	registration_log = ap.get 'registration_log'
	registrations = ap.get 'registrations'
	changes = ap.get 'changes'
	if not registration_log?
		registration_log = {}
	if not registrations?
		registrations = {}
	if not changes?
		changes = {}
	if not registration_log[user_id]?
		registration_log[user_id] = []
	reg = 
		action: action
		user_id: user_id
		date: (new Date()).getTime()
	if changes[user_id]?
		if reg.action is 'register' and changes[user_id].action is 'unregister'
			delete changes[user_id]
		if reg.action is 'unregistered' and changes[user_id].action is 'register'
			delete changes[user_id]
	else
		changes[user_id] = reg

	if registrations[user_id]? and reg.action is 'unregister'
		delete registrations[user_id]
	else if reg.action is 'register'
		registrations[user_id] = reg
	registration_log[user_id].push reg
	ap.put 'registration_log', registration_log
	ap.put 'registrations', registrations
	ap.put 'changes', changes
	ap.reg_changed = true

ap.register_sync = ->
	send_changes = []
	changes = ap.get 'changes'
	for id,change of changes
		send_changes.push change
	ap.api 'post user/registrations', {regs: send_changes}, (rsp) ->
		changes = ap.get 'changes'
		for success in rsp.successes
			delete changes[success.user_id]
		ap.put 'changes', changes
		ap.total_all = rsp.reg_all
		ap.total_hour = rsp.reg_past_hour
		ap.localizeRegistrations(rsp.registrations)
	ap.last_reg_sync = (new Date()).getTime()

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
