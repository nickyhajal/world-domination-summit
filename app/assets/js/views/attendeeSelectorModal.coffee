ap.Views.modal_attendee_selector = XView.extend
	timo: 0
	uByHash: {}
	events:
		'keyup .attendee-selection-search': 'search'
		'click #attendee-selection-results tr': 'row_click'
	initialize: ->
		@options.out = _.t('parts_modal-attendee-selector', @options.filler)
		@initRender()

	rendered: ->
		if ap.lastSearch? and ap.lastSearch
			$('.attendee-selection-search').val(ap.lastSearch)
			@search(ap.lastSearch)
			ap.lastSearch = false
		@initSelect2()
		@search()


	initSelect2: ->
		# Country Select
		year_select = $('#attendee-selection-year-select')
		years = [
			{id: '17', text: '2017'},
			{id: '16', text: '2016'},
			{id: '15', text: '2015'},
			{id: '14', text: '2014'}
		]
		yearById = {}
		for o in years
			yearById[o.id] = o
		year_select.select2
			placeholder: "Year"
			data: years
			multiple: true
			maximumSelectionLength: 10
			initSelection: (el, cb) ->
				objs = []
				for val in el.val().split(',')
					objs.push yearById[val]
				cb objs
			width: '150px'
		year_select.on 'change', (e) =>
			@search()

		type_select = $('#attendee-selection-type-select')
		types = [
			{id: '360', text: '360'},
			{id: 'connect', text: 'Connect'}
		]
		typeById = {}
		for o in types
			typeById[o.id] = o
		type_select.select2
			placeholder: "Ticket Type"
			data: types
			multiple: true
			maximumSelectionLength: 10
			initSelection: (el, cb) ->
				objs = []
				for val in el.val().split(',')
					objs.push typeById[val]
				cb objs
			width: '169px'
		type_select.on 'change', (e) =>
			@search()
		setTimeout ->
			$('#attendee-selection-year-select').select2('val', ['17'])
			$('#attendee-selection-type-select').select2('val', ['360'])
		, 100

	search: ->
		val = $('.attendee-selection-search').val()
		clearTimeout(@timo)
		@timo = setTimeout =>
			years = $('#attendee-selection-year-select').val()
			types = $('#attendee-selection-type-select').val()
			ap.api 'get users', {search: val, years: years, types: types}, (rsp) =>
					html = ''
					for atn in rsp.users
						atn = new ap.User(atn)
						type = 'type-'+atn.get('ticket_type')
						user_name_row = if atn.get('user_name').length then atn.get('user_name') else 'Hasn\'t Setup Account'
						user_name_link = if atn.get('user_name').length then atn.get('user_name') else atn.get('hash')
						@uByHash[user_name_link] = atn
						html += '<tr data-user="'+user_name_link+'" class="'+type+'">
							<td>
								<div class="attendee-selection-avatar" style="background:url('+atn.get('pic')+')"></div>
								<span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
								<div class="user_name">'+user_name_row+'</div>
							</td>
							<td>'+atn.get('email')+'</td>'
					$('#attendee-selection-results').html(html)
					$('#attendee-selection-start').hide()
					$('#attendee-selection-results-shell').show()
		, 500
	row_click: (e) ->
		user = $(e.currentTarget).data('user')
		ap.attendeeSelectionCb(@uByHash[user])

	whenFinished: ->
		ap.lastSearch = $('.attendee-selection-search').val()