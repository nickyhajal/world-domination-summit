###

 Primary client side code powering the WDS
 registration app

###

window.tk = (data)->
	if console
		console.log(data)
$ = jQuery
$('html').addClass('jsOn')
$ ->
	ap.init();
user = {}
ap.event_id = 0;
ap.page = 'home';
ap.Views = {}
ap.Routes = {}
ap.holdSearch = false
ap.mode = 'registration'
ap.eMap =
	id1:
		name: 'WDS Main Registration'
	# id999999:
	# 	name: 'Kindness'
	# 	title: 'Kindness Tracker'

ap.init = () ->
	if location.pathname.indexOf("kindness") > -1
		ap.mode = 'kind'
		$('#reg-nav h3').html("WDS Kindness App")
	$('body').on('click', '.reg-page-nav a', ap.showPage_click)
	if ap.me
		$('html').addClass('is-logged-in')
	ap.initAssets()
	_.whenReady 'me', ->
		ap.initSearch()
	$('body').on('click', '.register-button', ap.register_click)
	$('body').on 'click', '.go-home, .go-back', ->
		if ap.page is 'kinduser'
			ap.holdSearch = true
			# $('#kind-button').click()
			ap.showPage('search')
			setTimeout ->
				ap.holdSearch = false
			, 50
		else
			if ap.mode is 'kind'
				# ap.updateEvent('999999')
				ap.showPage('search')
			else
				$('.kind-btn').hide()
				ap.showPage('home')


ap.allUsers = {}
ap.registrations = {}
ap.initAssets = ->
	ap.register_sync()
	assets = 'reg_attendees,me,signin_events'
	ap.api 'get assets', {assets: assets}, (rsp) ->
		if rsp.reg_attendees
			setTimeout ->
				ap.Users.add(rsp.reg_attendees)
				ap.Users.sort()
			_.isReady 'users'
			, 500
		if rsp.me
			ap.me = new ap.User(rsp.me)
		if rsp.signin_events
			ap.events = rsp.signin_events
		ap.poll()
		if ap.mode is 'kind'
			# ap.updateEvent('999999')
			ap.showPage('search')
		else
			ap.showPage('home')
			$('.kind-btn').hide()
		_.isReady 'me'

ap.localizeRegistrations = (regs) ->
	ap.registrations = regs
	for id,reg of ap.get('registrations')
		ap.registrations[reg.user_id+'_'+reg.event_id] = 1

ap.getEvent = (id) ->
	for ev in ap.events
		if ev.event_id is id
			return ev
	return false

ap.initSearch = ->
	_.whenReady 'users', ->
		$('body')
		.on('keyup', '#register_search', ap.search)
		.on('click', '.search-row', ap.showKindUser)
		.on('click', '.kinded-button', ap.toggleKinded)
		.on 'click', '#clear-inp', ->
			$('#register_search').val('').keyup()
			setTimeout ->
				$('#register_search').focus()
			, 100


ap.search = ->
	val = $('#register_search').val()
	max = 90000
	results = []
	console.log(ap.event_id)
	ev = ap.getEvent(ap.event_id)
	console.log(ev)
	if val.length > 0
		$('#clear-inp').show()
		results = ap.Users.search(val)
	else
		$('#clear-inp').hide()
		results = ap.Users.models

	if ev and ap.event_id > 20 and (''+ap.event_id isnt '999999')
		final = []
		for r in results
			if ev.rsvps.indexOf(r.get('user_id')) > -1
				final.push(r)
		results = final
	html = ''
	count = 0
	for result in results
		count += 1
		if ap.registrations[result.get('user_id')+'_'+ap.event_id]
			str = 'Signed-In'
			reg_class = 'unregistered'
		else
			str = 'Sign-In'
			reg_class = 'registered'
		atype = result.get('type') ? 'attendee'
		ttype = result.get('ticket_type') ? 'attendee'
		if ttype == '360'
			ttype = 'attnd'
		if ttype == 'connect'
			ttype = 'attnd'
		if ttype == 'attendee'
			ttype = 'attnd'
		if ttype == 'attendee'
			ttype = 'attnd'
		if atype != 'attendee'
			ttype = atype
		if ttype is 'friend'
			ttype = 'f&f'
		if ttype == 'ambassador'
			ttype = 'ambsdr'
		notes = result.get('notes')
		noteStr = ''
		noteElm = ''
		if notes?.length > 0
			if notes.length == 1
				noteStr = '1 note'
			else
				noteStr = notes.length + ' notes'
			noteElm = '<div class="reg-notes">'+noteStr+'</div>'
		if ''+ap.event_id is '999999'
			if result.get('ticket_type') is 'attendee'
				kclass = 'not-kinded'
				if result.get('kinded')? and ''+result.get('kinded') is '1'
					kclass = 'is-kinded'
				if(ap.registrations[result.get('user_id')+'_1'])
					kclass += ' is-registered'
				else
					kclass += ' not-registered'

				html += '
					<a href="#" class="search-row kindness-row '+kclass+'" id="krow-'+result.get('user_id')+'" data-user_id="'+result.get('user_id')+'">
						<span style="background:url('+result.get('pic')+')"></span>
						<div class="reg-info">
							<div class="reg-name">'+result.get('first_name')+' '+result.get('last_name')+'</div>
						</div>
						<div data-user_id="'+result.get('user_id')+'" class="next-button">❯</div>
					</a>
				'
		else
			html += '
				<div class="search-row"  data-user_id="'+result.get('user_id')+'">
					<span style="background:url('+result.get('pic')+')"></span>
					<div class="reg-info">
						<div class="reg-name">'+result.get('first_name')+' '+result.get('last_name')+'</div>
				<div class="location">'+result.get('location')+'</div>
						<div class="reg-ttype">'+ttype+'</div>
						'+noteElm+'
					</div>
				<a href="#" data-user_id="'+result.get('user_id')+'" class="register-button '+reg_class+'">'+str+'</a>
				<div class="clear" />
				</div>
			'
	$('#search-results').html(html).show()


ap.showKindUser = (e) ->
	e.stopPropagation()
	e.preventDefault()
	$t = $(e.currentTarget)
	ap.active_user = $t.data('user_id')
	ap.showPage('kinduser')

ap.showPage_click = (e) ->
	e.stopPropagation()
	e.preventDefault()
	$t = $(e.currentTarget)
	event_id = $t.data('event_id')
	if event_id? and event_id
		ap.updateEvent(event_id)
		page = 'search'
	else
		page = $t.data('page')
	ap.showPage(page)

ap.showPage = (page) ->
	if page == 'home'
		$('.go-home', '#reg-nav').hide()
	else
		$('.go-home', '#reg-nav').show()
	$('.reg-panel-active').removeClass('reg-panel-active')
	$('#rp-'+page).addClass('reg-panel-active')
	ap.page = page
	if ap.onShow[page]?
		ap.onShow[page]()
ap.onShow = {}
ap.onShow.search = ->
	unless ap.holdSearch
		$('#register_search').val('')
		$('#clear-inp').hide()
		ap.search()
	id = 'id'+ap.event_id
	ev = if ap.eMap[id]? then ap.eMap[id] else {}
	name = if ev.name then ev.name else ap.event.what
	title = if ev.title? then ev.title else 'Sign-in for '+name
	$('h4.active-event').html(title)
ap.onShow.academies = ->
	acs = []
	html = ''
	for ev in ap.events
		if ev.type is 'academy'
			acs.push(ev)
			html += '<a href="#" data-event_id="'+ev.event_id+'">'+ev.what+'</a>'
	$('#academy-list').html(html)
ap.onShow.kinduser = ->
	user = ap.Users.get(ap.active_user)
	console.log(ap.event_id+">>>>>>>>>>>>>>>.")
	ap.active_user = user
	questions = [
			'Why did you travel <span class="ceil">{{ distance }}</span> miles to the World Domination Summit'
			'What are you excited about these days?'
			'What\'s your super-power?'
			'What is your goal for WDS 2016?'
			'What\'s your favorite song?'
			'What\'s your favorite treat?'
			'What\'s your favorite beverage?'
			'What\'s your favorite quote?'
			'What are you looking forward to during your time in Portland?'
		]
	count = 0
	html = ''
	for answer in user.get('answers')
		q = questions[answer.question_id - 1].replace('<span class="ceil">{{ distance }}</span> miles', '')
		html += '<div class="attendee-question-shell">'
		html += '<div class="question">'+q+'</div><div class="answer">'+answer.answer+'</div>'
		html += '</div>'
		count += 1
	notes = user.get('notes')
	html += '<div class="attendee-question-shell">'
	if notes.length
		for note in notes
			html += '<div class="answer">'+note.note+'</div>'
			count += 1
		html 
	else
		html += '<div class="answer">No notes about '+user.get('first_name')+'.</div>'
	html += '</div>'

	html += '<div class="clear"></div>'
	$('.k-name').html(user.get('first_name')+' '+user.get('last_name'))
	$('.k-info').html(html)
	# ap.updKinded()
	setTimeout ->
		$.scrollTo(0)
	, 80
ap.onShow.activities = ->
	acs = []
	html = ''
	for ev in ap.events
		if ev.type is 'activity' || ev.type is 'program'
			acs.push(ev)
			html += '<a href="#" data-event_id="'+ev.event_id+'">'+ev.what+'</a>'
	$('#activity-list').html(html)

ap.toggleKinded = (e) ->
	e.stopPropagation()
	e.preventDefault()
	$t = $(e.currentTarget)
	kind = '1'
	if $t.hasClass('kinded')
		kind = '0'
	ap.active_user.set('kinded', kind)
	ap.api 'post admin/kind', {user_id: ap.active_user.get('user_id'), kinded: kind}, (rsp) ->
	ap.updKinded()

ap.updKinded = ->
	btn = $('.kinded-button')
	user = ap.active_user
	kinded = user.get('kinded') ? '0'
	kclass = 'not-kinded'
	if parseInt(kinded)
		kclass = 'is-kinded'
		btn.html('Kinded - Tap to Unkind').addClass('kinded')
	else
		btn.html('Mark as Kinded').removeClass('kinded')
	$('#krow-'+user.get('user_id'))
	.removeClass('not-kinded')
	.removeClass('is-kinded')
	.addClass(kclass)

ap.updateEvent = (event_id) ->
	ap.event_id = event_id
	ap.event = ap.getEvent(event_id)

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
	e.stopPropagation()
	el = $(e.currentTarget)
	user_id = el.data('user_id')
	event_id = ap.event_id
	key = user_id+'_'+event_id
	if ap.registrations[key]?
		action = 'unregister'
		el.html('Sign-In').addClass('registered').removeClass('unregistered')
		delete ap.registrations[key]
	else
		action = 'register'
		el.html('Signed-In').addClass('unregistered').removeClass('registered')
		ap.registrations[key] = '1'
	ap.register(user_id, action)

ap.register = (user_id, action) ->
	event_id = ap.event_id
	key = user_id+'_'+event_id
	registration_log = ap.get 'registration_log'
	registrations = ap.get 'registrations'
	changes = ap.get 'changes'
	if not registration_log?
		registration_log = {}
	if not registrations?
		registrations = {}
	if not changes?
		changes = {}
	if not registration_log[key]?
		registration_log[key] = []
	reg =
		action: action
		user_id: user_id
		event_id: event_id
		date: (new Date()).getTime()
	if changes[key]?
		if reg.action is 'register' and changes[key].action is 'unregister'
			delete changes[key]
		if reg.action is 'unregistered' and changes[key].action is 'register'
			delete changes[key]
	else
		changes[key] = reg

	if registrations[key]? and reg.action is 'unregister'
		delete registrations[key]
	else if reg.action is 'register'
		registrations[key] = reg
	registration_log[key].push reg
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
			delete changes[success.user_id+'_'+success.event_id]
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
