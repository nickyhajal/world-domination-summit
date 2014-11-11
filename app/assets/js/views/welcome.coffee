###

	The view someone sees the very first time
	they go to the WDS site

	This will appear until their 'intro' count
	is above the number of welcome tabs

###

ap.Views.welcome = XView.extend

	events: 
		'click .twitter-disconnect': 'disconnectTwitter'
		'click .finish-welcome': 'finishWelcome'
		'click .send-tweet': 'sendTweet'

	initialize: ->
		@options.sidebar = 'welcome'
		@options.out = _.template @options.out, ap.me.attributes
		@initRender()
		self = this
		$('#content_shell').addClass('start')
		unless ap.upload_success?
			ap.upload_success = (url) ->
				ap.me.set('pic', url)
				self.syncAvatar()

	rendered: ->
		# Setup Animation
		$('#sidebar-shell').addClass('faded-out')


		# Show correct content for if attended
		if ap.me.attendedBefore()
			$('html').addClass('attended-before')
		else
			$('html').addClass('attended-never')

		setTimeout =>

			# Start animation
			$('#content_shell').removeClass('start')
			$('html').addClass('hide-counter')
			@sidebarNumbers()
			@usernameChanged(ap.me.get('user_name'))
			@syncTwitterBox()
			@syncAvatar()
			@initSelect2()
			@syncLastPosition()
		, 5

		ap.me.on('change:user_name', @usernameChanged, @)
		XHook.hook('tab-before-show-welcome_tabs', @saveAndContinue)

	###
		Use Select2 to have nice select boxes for the address fields
	###
	initSelect2: ->
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
			width: '300px'
		country_select.on 'change', (e) =>
			@regionSync()
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
				width: '300px'

			shell.scan()
		else
			ap.me.set('region', '')

	###
		Clear the old avatar example and display the new one
	###
	syncAvatar: ->
		if ap.me.get('pic')?
			$('.current-avatar').show()
			$('.avatar-shell').empty().append $('<img/>').attr('src', ap.me.get('pic').replace('_normal', ''))

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
				$('.tweet-box textarea').val('Just setup my attendee profile for WDS! Check it out: http://wds.fm/~'+user_name+' #wds2015')
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
		We'll add numbers to the sidebar tabs to give a sense of progression
	###
	sidebarNumbers: ->
		count = 0
		$('.tab-link').each ->
			count += 1
			$(this).prepend $('<span/>').html(count+'.').attr('class', 'sidebar-num')
		setTimeout ->
			$('#sidebar-shell').removeClass('faded-out')
		, 10

	###
		Goes to the last tracked tab the user was on
	###
	syncLastPosition: ->
		for i in [0..(ap.me.get('intro')+1)]
			$('.tab-link').eq(i).removeClass('tab-disabled')
		$('.tab-link').eq(ap.me.get('intro')).click()

	###
		Saves the latest changes to ap.me
		and allows the tab to switch
	###
	saveAndContinue: (tab, switchTab) ->
		btn = $('.tab-next:visible')
		original_btn_val = btn.html()
		btn.html('Saving...')
		$('.tab-link').eq(tab.num+1).removeClass('tab-disabled')
		if $('input[name="new_password"]').is(':visible') and $('input[name="new_password"]').val().length < 5
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
						$.scrollTo(0)
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
				$.scrollTo(0)

	###
		Updates the username preview as it changes
	###
	usernameChanged: (user_name) ->
		if not user_name? or not user_name.length
			user_name = 'username'
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
		ap.me.set('intro', 8)
		if ap.me.changedSinceSave.user_id?
			ap.me.save ap.me.changedSinceSave, 
				patch: true
		ap.navigate('hub')


	###
		When this view is destroyed, this will be called
	###
	whenFinished: ->
		ap.me.on('change:user_name', @usernameChanged, @)
		$('.settings-link').unbind()
		$('html')
			.removeClass('attended-before')
			.removeClass('hide-counter')
