ap.Views.admin_user = XView.extend
	ticketTimo: 0
	events:
		'keyup .manifest-search': 'search'
		'click #manifest-results tr': 'row_click'
		'submit #admin-user-update': 'userInfo_submit'
		'click .toggle-ticket': 'ticketToggle_click'
		'click .do-toggle-ticket': 'doTicketToggle_click'
	initialize: ->

		params = {}
		params.inc_hash = 1
		if _.isNaN(parseInt(@options.extra))
			params.user_name = @options.extra
		else
			params.user_id = @options.extra
		ap.api 'get user', params, (rsp) =>
			@user = new ap.User(rsp.user)
			@options.out = _.template @options.out, @user.attributes
			@initRender()
	rendered: ->
		@initSelect2()
		@initTickets()
		$('input[name="type"]').val(@user.get('type'))
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
		@initCapabilities()
	regionSync: ->
		shell = $('#region-shell')
		val = false
		if shell.data('value')?
			val = shell.data('value')
		country = $('#country-select').val()
		select = $('<input/>').attr('id', 'region-select').attr('name', 'region').attr('type', 'hidden')
		select.val(val)
		shell.empty()
		if ap.provinces[country]?
			provinces = ap.provinces[country]
			map =
				US: ['State', 'short', 'name']
				GB: ['Region','name', 'region']
				CA: ['Province','short', 'name']
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

	initTickets: ->
		if +@user.get('attending'+ap.yr) > 0
			type = if @user.get('ticket_type') is 'connect' then 'Connect' else '360'
			text = 'Attending WDS '+type
			btn = '<a href="#" class="cancel-ticket toggle-ticket button">Cancel Ticket</a>'
		else
			text = 'Not Attending WDS '+ap.year
			btn = '
				<a href="#" class="enable-ticket toggle-ticket button" data-type="360">Give 360</a>
				<a href="#" class="enable-ticket toggle-ticket button" data-type="connect">Give Connect</a>
			'

		$('.ticket-shell').html('
			<div class="active-ticket">
				<h4>'+text+'</h4>'+btn+'
				<div class="clear"></div>
			</div>
		')

	initCapabilities: ->
    if @user.get('capabilities')?
    	capabilities = @user.get('capabilities')?
	    available_top_level_capabilities = @user.get('available_top_level_capabilities')
	    capabilities_select = $('#capabilities-select')
	    capabilities = Array()
	    capabilities.push {id: capability, text: capability} for capability in available_top_level_capabilities

	    capabilities_select.select2
	      placeholder: "Capabilities"
	      data: capabilities
	      multiple: true
	      initSelection: (el, cb) ->
	        selection = Array()
	        selection.push({id: cap, text: cap}) for cap in el.val().split(",")
	        cb selection
	      width: '300px'


	userInfo_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		form.admin = 1
		ap.api 'put user', form, (rsp) ->
			btn.finish()

	ticketToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		el.removeClass('toggle-ticket')
		el.addClass('do-toggle-ticket')
		if el.hasClass('cancel-ticket')
			action = 'Cancel'
		else
			action = 'Give'
		$(el).html('Click Again to '+action)
		@ticketTimo =  setTimeout ->
			el.html(action+' Ticket')
			el.addClass('toggle-ticket')
			el.removeClass('do-toggle-ticket')
		, 1200

	doTicketToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		clearTimeout(@ticketTimo)
		if el.hasClass('cancel-ticket')
			val = '-1'
			type = ''
		else
			val = '1'
			type = el.data('type')
		post =
			admin: 1
			user_id: @user.get('user_id')
		post['attending'+ap.yr] = val
		post['ticket_type'] = type
		@user
		.set('attending'+ap.yr, val)
		.set('ticket_type', type)
		.save(post, {patch: true})
		@initTickets()

