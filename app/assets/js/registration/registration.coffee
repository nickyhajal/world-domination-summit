###

 Primary client side code powering the WDS
 registration app

###

bentos = JSON.parse(
  '{"176":["18","19","19"],"775":["19"],"851":["19"],"871":["20"],"872":["19"],"976":["19","19"],"985":["19"],"1004":["18","18","18"],"1130":["18"],"1169":["20"],"1201":["18"],"1221":["19"],"1222":["19"],"1399":["20"],"1401":["19"],"1411":["19"],"1530":["20"],"1715":["19"],"1731":["19"],"1864":["19","19"],"2048":["19"],"2109":["19"],"2297":["19"],"2439":["19"],"2446":["18"],"2464":["19"],"2519":["19"],"2558":["19"],"2565":["18"],"2672":["20"],"2813":["19"],"2889":["19"],"3219":["19"],"3275":["18"],"3430":["20"],"3465":["20"],"3469":["20","20"],"3493":["19","19","19"],"3496":["18"],"3710":["18"],"3720":["19","19"],"3837":["20","20"],"4050":["18"],"4144":["19","19"],"4170":["20"],"4203":["18"],"4403":["18"],"4442":["18"],"4487":["18"],"4502":["20"],"4527":["18"],"4552":["18"],"4581":["20"],"4601":["20"],"4680":["19"],"4694":["18"],"4742":["18"],"4747":["18"],"4751":["19"],"4760":["18"],"4921":["19"],"5092":["18"],"5152":["18"],"5264":["19"],"5305":["20"],"5461":["19"],"5503":["19","19"],"5616":["20"],"5650":["19"],"5718":["19"],"5730":["20"],"5831":["19"],"6096":["20"],"6184":["18"],"6258":["20"],"6408":["20"],"6433":["18"],"6465":["18"],"6592":["18"],"6618":["20"],"6645":["19"],"6717":["18"],"6759":["20"],"6839":["19"],"6902":["19"],"7029":["18"],"7095":["20"],"7148":["18"],"7207":["19"],"7240":["19"],"7251":["19"],"7255":["19"],"7279":["20","20"],"7424":["20"],"7450":["20"],"7451":["20"],"7462":["19","19"],"7469":["19"],"7496":["18","19"],"7578":["19"],"7628":["20"],"7680":["19"],"7689":["20","20"],"7705":["19"],"7760":["19"],"7912":["18"],"7965":["19"],"8052":["19","20","20"],"8067":["19"],"8106":["20"],"8128":["20"],"8161":["20","20"],"8186":["19"],"8201":["20"],"8217":["18"],"8272":["18","20"],"8310":["18"],"8314":["20"],"8330":["19"],"8342":["19","19"],"8375":["20"],"8411":["18"],"8442":["19"],"8465":["18"],"8579":["18"],"8710":["20"],"8821":["19"],"8866":["18"],"8867":["19"],"8876":["19"],"8890":["20"],"8984":["20","20"],"9019":["20"],"9046":["19"],"9219":["19","19"],"9233":["20"],"9250":["18"],"9252":["20"],"9256":["19"],"9261":["20"],"9264":["19"],"9272":["18"],"9320":["20"],"9330":["19","19"],"9360":["18"],"9452":["20"],"9501":["19"],"9701":["19"],"9710":["18"],"9734":["19"],"9751":["20"],"9773":["20"],"9779":["18"],"9781":["20"],"9891":["19"],"9936":["19"],"10233":["18"],"10257":["18"],"10283":["19"],"10291":["19"],"10295":["18"],"10298":["19"],"10299":["19"],"10305":["20"],"10358":["19"],"10377":["18"],"10379":["19"],"10399":["18"],"10450":["19"],"10464":["20"],"10468":["18"],"10477":["19"],"10478":["18"],"10484":["19"],"10526":["20"],"10530":["19"],"10565":["20","20"],"10566":["19"],"10569":["20"],"10582":["19"],"10589":["18"],"10610":["19"],"10615":["19"],"10625":["20"],"10649":["19"],"10664":["19"],"10694":["20"],"10710":["19"],"10779":["20"],"10907":["18"],"10928":["20"],"10986":["19"],"11016":["20"],"11087":["19"],"11104":["20"],"11105":["18"],"11109":["19"],"11161":["20"],"11293":["19"],"11294":["20","20"],"11297":["18"],"11299":["19"],"11306":["20"],"11307":["20"],"11313":["18"],"11319":["20"],"11326":["19"],"11327":["19"],"11328":["19","19"],"11330":["20"],"11332":["20"],"11344":["19"],"11345":["19","20"],"11347":["18"],"11348":["19"],"11352":["20"],"11355":["20"],"11362":["19"],"11367":["18","19"],"11383":["20"],"11384":["20"],"11412":["19"],"11424":["19"],"11439":["18"],"11450":["19"],"11471":["19"],"11472":["19"],"11492":["20"],"11498":["19"],"11509":["18"],"11512":["20"],"11522":["18"],"11537":["18"],"11539":["19"],"11548":["20"],"11550":["19"],"11556":["20"],"11557":["19"],"11560":["19"],"11561":["20","20"],"11564":["20"],"11572":["18"],"11574":["20"],"11579":["18"],"11583":["18"],"11589":["18"],"11591":["20"],"11594":["20"],"11595":["19"],"11608":["18"],"11611":["19"],"11616":["18","20"],"11633":["19","19"],"11634":["20"],"11635":["19"],"11642":["19"],"11653":["19","19"],"11674":["18"],"11681":["19"],"11688":["20"],"11690":["20"],"11696":["19"],"11697":["19","19"],"11709":["19"],"11721":["20"],"11760":["20"],"11797":["19"],"11798":["19"],"11800":["20"],"11805":["19"],"11808":["20"],"11812":["19","19"],"11817":["19"],"11822":["20"],"11826":["19"],"11837":["19"],"11844":["19"],"11847":["20"],"11884":["18"],"11899":["19"],"11908":["19"],"11909":["20"],"11929":["19"],"11930":["18"],"11934":["19"],"11938":["20"],"11961":["20"],"11979":["19"]}'
);
bTypes = {
	"18": "Sandwich",
	"19": "Chicken",
	"20": "Veggie",
}

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


	################ CHECK BUTTON
	$('body').on 'click', '.loaded .checkbutton', (e) ->
		e.preventDefault()
		e.stopPropagation()
		$t = $(this)
		if $t.hasClass('loading')
			return false
		user_id = $t.data('user_id')
		col = $t.data('id')
		sendCol = col
		inx = $t.data('inx')
		isSelected = $t.hasClass('selected')
		val = false
		if col is 'bnt'
			sendCol = 'bentos'
			vals = []
			$('.bentobtn').each((i) ->
				if i is inx
					vals.push(if $(this).hasClass('selected') then '0' else '1')
				else
					vals.push(if $(this).hasClass('selected') then '1' else '0')
			)
			val = vals.join(',')
		if !val
			val = if isSelected then '0' else '1'

		$t.addClass('loading')
		ap.api 'post user/register_extra', {col: sendCol, val: val, user_id: user_id}, (rsp) ->
			$t.removeClass('loading')
			syncButtonState(col, user_id, !isSelected, inx)
		return false

	####################################

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
	ev = ap.getEvent(ap.event_id)
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






###
           USER PROFILE
###
lastStateData = {}
syncButtonState = (pre, user_id, sel, inx = 0, bnt = 0) ->
	names =
		glb: 'Lunchbox'
		gsp: 'To-go Ware'
	if pre is 'bnt'
		btn = $('#'+pre+'-'+inx+'-'+user_id)
	else
		btn = $('#'+pre+'-'+user_id)
		name = names[pre]
	if sel
		btn.addClass('selected')
		if pre isnt 'bnt'
			btn.text("Received "+name+"!")
	else
		btn.removeClass('selected')
		if pre isnt 'bnt'
			btn.text("Mark "+name+" Received")



ap.onShow.kinduser = ->
	user = ap.Users.get(ap.active_user)
	user_id = user.get('user_id')
	tk user_id
	bnts = bentos[''+user_id]
	tk bnts
	ap.api 'get usersp', {user_id: user_id}, (rsp) ->
		syncButtonState('glb', user_id, +rsp.glb is 1)
		syncButtonState('gsp', user_id, +rsp.gsp is 1)
		$('#atn-controls').removeClass('not-loaded').addClass('loaded')
		c = 0
		for b in bnts
			b = bTypes[b]
			sel = false
			if rsp.bentos && rsp.bentos.length
				bs = rsp.bentos.split(',')
				sel = +bs[c] is 1
			syncButtonState('bnt', user_id, sel, c)
			c += 1
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
	nsp = +user.get('nsp')
	html += '<div id="atn-controls" class="attendee-question-shell not-loaded">'
	html += '	<div class="answer">'
	html += '		<h5>Lunchbox</h5>'
	html += '		<button id="glb-'+user_id+'" class="checkbutton" data-id="glb" data-user_id="'+user_id+'">&nbsp;</button>'
	if bnts and bnts.length > 0
		html += '		<h5>Bentos</h5>'
		c = 0
		for b in bnts
			b = bTypes[b]
			html += '		<button id="bnt-'+c+'-'+user_id+'" class="checkbutton bentobtn" data-btype='+b+' data-id="bnt" data-inx="'+c+'" data-user_id="'+user_id+'">'+b+' Bento</button>'
			c += 1
	if nsp > 0
		html += '		<h5>To-go Ware</h5>'
		html += '		<button id="gsp-'+user_id+'" class="checkbutton" data-id="gsp" data-user_id="'+user_id+'">&nbsp;</button>'
	html += '	</div>'
	html += '</div>'

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
