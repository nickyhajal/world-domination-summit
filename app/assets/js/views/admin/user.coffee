ap.Views.admin_user = XView.extend
	ticketTimo: 0
	events: 
		'keyup .manifest-search': 'search'
		'click #manifest-results tr': 'row_click'
		'submit #admin-user-update': 'userInfo_submit'
		'click .toggle-ticket': 'ticketToggle_click'
		'click .do-toggle-ticket': 'doTicketToggle_click'
	initialize: ->
		ap.api 'get user', {user_name: @options.extra}, (rsp) =>
			@user = new ap.User(rsp.user)
			@options.out = _.template @options.out, @user.attributes
			@initRender()
	rendered: ->
		@initSelect2()
		@initTickets()
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
		if @user.get('attending'+ap.yr) is '1'
			text = 'Attending WDS '+ap.year
			clss = 'cancel-ticket'
			action = 'Cancel'
		else
			text = 'Not Attending WDS '+ap.year
			clss = 'enable-ticket'
			action = 'Give'

		$('.ticket-shell').html('
			<div class="active-ticket">
				<h4>'+text+'</h4>
				<a href="#" class="'+clss+' toggle-ticket button">'+action+' Ticket</a>
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
		else
			val = '1'
		@user
		.set('attending14', val)
		.save({attending14: val, admin: 1, user_id: @user.get('user_id')}, {patch: true})
		@initTickets()

