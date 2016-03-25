###

	The view someone sees the very first time
	they go to the WDS site

	This will appear until their 'intro' count
	is above the number of welcome tabs

###
ap.WELCOME_STEPS = 10
ap.Views.welcome = XView.extend

	events:
		'click .twitter-disconnect': 'disconnectTwitter'
		'click .finish-welcome': 'finishWelcome'
		'click .send-tweet': 'sendTweet'
		'click .tab-next-btn': 'next'
		'click .tab-prev-btn': 'prev'
		'click .tab-save-next': 'next'

	initialize: ->
		if ap.me.get('intro') >= ap.WELCOME_STEPS
			ap.navigate('settings')
		else
			# @options.sidebar = 'welcome'
			@options.out = _.template @options.out, ap.me.attributes
			@initRender()
			self = this
			# $('#content_shell').addClass('start')
			unless ap.upload_success?
				ap.upload_success = (url) ->
					ap.me.set('pic', url)
					self.syncAvatar()

	rendered: ->
		# Setup Animation
		# $('#sidebar-shell').addClass('faded-out')


		# Show correct content for if attended
		if ap.me.attendedBefore()
			$('html').addClass('attended-before')
		else
			$('html').addClass('attended-never')

		setTimeout =>

			# Start animation
			# setTimeout =>
			# 	$('#content_shell').removeClass('start')
			# , 300
			$('html').addClass('hide-counter')
			# @sidebarNumbers()
			@syncLastPosition()
			@syncDistance(ap.me.attributes)
			@usernameChanged(ap.me.get('user_name'))
			@syncTwitterBox()
			@syncAvatar()
			@initSelect2()
			setTimeout ->
				ap.loading false
				$('#welcome-logo').css('opacity', '1')
				$('#tab-shell-welcome_tabs').css('opacity', '1')
			, 1200
			if ap.me?.get('has_pw')? and ap.me.get('has_pw')
				$('#tab-panel-the-basics .form-section').eq(1).hide()
		, 5

		XHook.hook('model-me-user_name-changed', @usernameChanged)
		XHook.hook('tab-before-show-welcome_tabs', @saveAndContinue)
		XHook.hook('interests-updated', @interestsUpdated)

	###
		Use Select2 to have nice select boxes for the address fields
	###
	initSelect2: ->

		# Country Select
		country_select = $('#country-select')
		countries = []
		countries.push {id: country.alpha2, text: country.name} for country in ap.countries.all
		countryById = {}
		for c in countries
			countryById[c.id] = c
		country_select.select2
			placeholder: "Country"
			data: countries
			initSelection: (el, cb) ->
				cb countryById[el.val()]
			width: '276px'

		# Calling Codes
		calling_select = $('#calling-code-select')
		callingCountries = []
		for country in ap.countries.all
			if country.callingCodes.length
				code = country.callingCodes[0]
				id = code.replace('+','')
				text = '('+code+') '+country.name
			callingCountries.push {id: id, text: text}
		callingCountriesById = {}
		for c in callingCountries
			callingCountriesById[c.id] = c
		calling_select.select2
			placeholder: "Country Code"
			data: callingCountries
			value: 'US'
			initSelection: (el, cb) ->
				cb callingCountriesById[el.val()]
			width: '276px'
		setTimeout ->
			unless calling_select.select2('val')
				calling_select.select2('val', '1').trigger('change')
				calling_select.val('1').trigger('change')
		, 1000

		# Calling Codes
		accom_select = $('#accommodation-select')
		accomsById = {}
		for a in ap.accoms
			accomsById[a.id] = a
		accom_select.select2
			placeholder: "Accomodations"
			data: ap.accoms
			initSelection: (el, cb) ->
				cb accomsById[el.val()]
			width: '276px'

		# State/Province
		@regionSync()

	regionSync: ->
		shell = $('#region-shell')
		country = $('#country-select').val()
		select = $('<input/>').attr('id', 'region-select').attr('class', 'model-me').attr('name', 'region').attr('type', 'hidden')
		shell.empty()
		if ap.provinces[country]?
			provinces = ap.provinces[country]
			map =
				US: ['State', 'short', 'name']
				GB: ['Region','region', 'region']
				CA: ['Province','name', 'name']
				CN: ['Province','name','name']
				AU: ['Province','name','name']
				DE: ['Region','name','name']
				MX: ['Region','name','name']
			label = $('<label/>').html(map[country][0])
			shell.append(label)
			shell.append(select)
			regions = []
			regions.push {id: province[map[country][1]], text: province[map[country][2]]} for province in provinces
			regionById = {}
			tmp = []
			for r in regions
				if not regionById[r.id]?
					regionById[r.id] = r
					tmp.push r
			regions = tmp

			select.select2
				placeholder: map[country][0]
				data: regions
				initSelection: (el, cb) ->
					cb regionById[el.val()]
				width: '276px'

			shell.scan()
		else
			ap.me.set('region', '')

	###
		Clear the old avatar example and display the new one
	###
	syncAvatar: ->
		if ap.me.get('pic')?
			$('.current-avatar').show()
			$('.avatar-shell').empty().append $('<img/>').attr('src', ap.me.getPic(256)+'&'+(''+(+new Date())))

	###
		Show the appropriate twitter box based on whether or not
		the user has connected to twitter
	###
	syncTwitterBox: ->
		if ap.me.get('twitter')?.length
			$('.twitter-connected').show()
			$('.twitter-not-connected').hide()
			if ap.me.get('user_name')? and ap.me.get('user_name').length isnt 40
				user_name = ap.me.get('user_name')
				$('.tweet-box textarea').val('Just setup my attendee profile for WDS! Check it out: http://wds.fm/~'+user_name+' #wds2016')
				$('.tweet-box').show()
		else
			$('.twitter-connected').hide()
			$('.twitter-not-connected').show()
			$('.tweet-box').hide()

	###
		Disconnect the user from twitter
	###
	disconnectTwitter: (e) ->
		ap.me.set('twitter', '')
		@syncTwitterBox()
		ap.api 'delete user/twitter'
		e.preventDefault()


	###
		Goes to the last tracked tab the user was on
	###
	syncLastPosition: ->
		setTimeout =>
			$('.tab-panel').each ->
				$t = $(this)
				$t.data('height', $t.outerHeight()+'px')
		, 400
		setTimeout =>
			@goto parseInt(ap.me.get('intro'))
		, 500

	interestsUpdated: ->
		_.whenReady 'welcome-positions', =>
			$t = $('#tab-panel-interests')
			$t.attr 'style', 'opacity:0;'
			eClass = $t.attr('class')
			$t.attr('class', 'tab-panel')
			setTimeout =>
				$t.data('height', $t.outerHeight()+'px')
				$t.attr('class', eClass)
				$t.attr 'style', ''
			, 1000



	next: (e) ->
		e?.stopPropagation?()
		w = $('#tab-shell-welcome_tabs')
		$('.tab-panel', w).css {height: '460px'}
		$('.tab-panel-prev', w).attr 'class', 'tab-panel tab-panel-prev-hidden'
		$('.tab-panel-active', w).attr 'class', 'tab-panel tab-panel-prev'
		$('.tab-panel-next', w).attr 'class', 'tab-panel tab-panel-active'
		$('.tab-panel-next-hidden', w).eq(0).attr 'class', 'tab-panel tab-panel-next'
		@updPosition()
		@updMe()

	prev: ->
		e?.stopPropagation?()
		w = $('#tab-shell-welcome_tabs')
		$('.tab-panel', w).css {height: '460px'}
		$('.tab-panel', w).css {height: '460px'}
		$('.tab-panel-next', w).attr 'class', 'tab-panel tab-panel-next-hidden'
		$('.tab-panel-active', w).attr 'class', 'tab-panel tab-panel-next'
		$('.tab-panel-prev', w).attr 'class', 'tab-panel tab-panel-active'
		$('.tab-panel-prev-hidden', w).last().attr 'class', 'tab-panel tab-panel-prev'
		@updPosition()

	goto: (inx) ->
		i = 0
		activeFound = false
		nextFound = false
		$('.tab-panel').each ->
			$t = $(this)
			if inx > i
				$('.tab-panel-last').removeClass('tab-panel-last')
				$t.attr 'class', 'tab-panel tab-panel-prev-hidden tab-panel-last'
			else if inx < i
				if activeFound and not nextFound
					$t.attr 'class', 'tab-panel tab-panel-next'
					nextFound = true
				else
					$t.attr 'class', 'tab-panel tab-panel-next-hidden'
			else
				activeFound = true
				$t.addClass('tab-panel-active')
				$t.css {'height': $t.data('height')}
				$('.tab-panel-last').attr 'class', 'tab-panel tab-panel-prev'
			i += 1
		@updPosition()

	updPosition: ->
		sW = $('#page_content').outerWidth()
		sW2 = sW / 2
		pW = 680
		pW2 = pW / 2
		pL = sW2 - pW2
		tk sW-pW
		sideW = 600
		nextL = 20 + sideW + pW + 20
		prL = -135
		$('.tab-panel-active').css {'height': $('.tab-panel-active').data('height')}
		$('#welcome_styles').remove()
		style = $('<style/>')
		.attr('id', 'welcome_styles')
		.attr('type', 'text/css')
		.text '
			.tab-panel-active {
				left:' + _.x(pL) + '
			}
			div.tab-panel-prev-hidden {
				left: '+ _.x(0)+'
			}
			.tab-panel-prev, .tab-panel-prev-hidden, .tab-prev-btn {
				left: '+ _.x(prL)+';
				width: '+ _.x(sideW)+';
			}
			div.tab-panel-next-hidden {
				left: '+ _.x(sW-sideW+120)+';
			}
			.tab-panel-next, .tab-panel-next-hidden, .tab-next-btn {
				left: '+ _.x(sW-sideW+120)+';
				width: '+ _.x(sideW)+';
			}
		'
		$('body').append style
		_.nowReady 'welcome-positions'

	syncDistance: (user) ->
		distance = Math.floor(user.distance)
		str = 'Why did you decide to attend the World Domination Summit?'
		if distance > 10
			str = 'Why did you decide to make the '+distance+' mile journey to the World Domination Summit?'
		$('#travel-label').html str

	updMe: ->
		if !(ap.me?.get('has_pw')? and ap.me.get('has_pw')) && $('input[name="new_password"]').is(':visible') and $('input[name="new_password"]').val().length < 5
			btn.html('Your password should be at least 6 characters.').addClass('btn-error')
			setTimeout ->
				btn.html(original_btn_val).removeClass('btn-error')
			, 2000
		else
			onTab = ($('.tab-panel-active').index()-1)
			if ap.me.get('intro') < onTab
				ap.me.set('intro', onTab-1)
			if ap.me.changedSinceSave.user_id?
				ap.me.save ap.me.changedSinceSave,
					patch: true
					success: (model, rsp) =>
						tk 'SUCCESS!'
						tk rsp
						if rsp.user
							@syncDistance(rsp.user)
					error: (rsp) ->
			else

	###
		Saves the latest changes to ap.me
		and allows the tab to switch
	###
	saveAndContinue: (tab, switchTab) ->
		btn = $('.tab-next:visible')
		original_btn_val = btn.html()
		btn.html('Saving...')
		$('.tab-link').eq(tab.num+1).removeClass('tab-disabled')
		if !(ap.me?.get('has_pw')? and ap.me.get('has_pw')) && $('input[name="new_password"]').is(':visible') and $('input[name="new_password"]').val().length < 5
			btn.html('Your password should be at least 6 characters.').addClass('btn-error')
			setTimeout ->
				btn.html(original_btn_val).removeClass('btn-error')
			, 2000
		else
			if ap.me.get('intro') < tab.num + 1
				ap.me.set('intro', tab.num+1)
			if ap.me.changedSinceSave.user_id?
				ap.me.save ap.me.changedSinceSave,
					patch: true
					success: ->
						switchTab()
						$.scrollTo(0, 3000)
						btn.html(original_btn_val)
					error: (rsp) ->
						ap.Notify.now
							msg: rsp.msg
							state: 'error'
						btn.html 'Oops, small problem.'
						setTimeout ->
							btn.html(original_btn_val)
						, 1000
			else
				switchTab()
				$.scrollTo(0, 3000)

	###
		Updates the username preview as it changes
	###
	usernameChanged: (user_name, hey) ->
		user_name = ap.me.get('user_name')
		if not user_name? or not user_name.length
			user_name = '&lt;username&gt;'
		$('.user_name-preview').html(user_name)

	sendTweet: (e) ->
		$t = $(e.currentTarget)
		tweet = $('.tweet-box textarea').val()
		$t.html('Tweeting...')
		ap.api 'post user/tweet', {tweet: tweet}, (rsp) ->
			$t.html('Tweet Sent!')
			setTimeout ->
				$('.tweet-box-shell')
					.css('min-height', '0')
					.css('height', '0')
					.css('margin', '0')
			, 1200

	finishWelcome: (e) ->
		e.preventDefault()
		ap.me.set('intro', ap.WELCOME_STEPS)
		if ap.me.changedSinceSave.user_id?
			ap.me.save ap.me.changedSinceSave,
				patch: true
		ap.navigate('hub')


	###
		When this view is destroyed, this will be called
	###
	whenFinished: ->
		ap.me.off('change:user_name', @usernameChanged)
		$('.settings-link').unbind()
		$('html')
			.removeClass('attended-before')
			.removeClass('hide-counter')
