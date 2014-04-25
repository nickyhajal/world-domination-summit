###

	The view someone sees the very first time
	they go to the WDS site

	This will appear until their 'intro' count
	is above the number of welcome tabs

###

ap.Views.settings = XView.extend

	events: 
		'click .twitter-disconnect': 'disconnectTwitter'

	initialize: ->
		@options.sidebar = 'settings'
		@options.out = _.template @options.out, ap.me.attributes
		@initRender()
		self = this
		unless ap.upload_success?
			ap.upload_success = (url) ->
				ap.me.set('pic', url)
				self.syncAvatar()

	rendered: ->
		setTimeout =>
			@initSelect2()
			@syncTwitterBox()
			@usernameChanged()
		, 5

		ap.me.on('change:user_name', @usernameChanged, @)

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
			$('.twitter-connected', @el).show()
			$('.twitter-not-connected', @el).hide()
		else
			$('.twitter-connected', @el).hide()
			$('.twitter-not-connected', @el).show()

	###
		Disconnect the user from twitter
	###
	disconnectTwitter: (e) ->
		ap.me.set('twitter', '')
		@syncTwitterBox()
		ap.api 'delete user/twitter'
		e.preventDefault()


	###
		Saves the latest changes to ap.me
		and allows the tab to switch
	###
	saveMe: (tab) ->
		btn = $('.tab-next:visible')
		original_btn_val = btn.val()
		btn.val('Saving...')
		if ap.me.changedSinceSave.user_id?
			ap.me.save ap.me.changedSinceSave, 
				patch: true
				success: ->
					btn.val('Saved!')
					setTimeout ->
						btn.val(original_btn_val)
					, 1200
				error: (rsp) ->
					btn.val rsp.msg
					setTimeout ->
						btn.val(original_btn_val)
					, 2000
		else
			btn.val 'Saved!'
			setTimeout ->
				btn.val(original_btn_val)
			, 1200

	###
		Updates the username preview as it changes
	###
	usernameChanged: (user_name) ->
		if not user_name? or not user_name.length
			user_name = 'username'
		$('.user_name-preview').html(user_name)

	###
		When this view is destroyed, this will be called
	###
	whenFinished: ->
		ap.me.off('change:user_name', @usernameChanged, @)
		$('.settings-link').unbind()
		$('html')
			.removeClass('attended-before')
			.removeClass('hide-counter')
