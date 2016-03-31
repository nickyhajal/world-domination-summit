ap.Views.admin_manifest = XView.extend
	timo: 0
	events:
		'keyup .manifest-search': 'search'
		'click #manifest-results tr': 'row_click'
	initialize: ->
		@initRender()

	rendered: ->
		if ap.lastSearch? and ap.lastSearch
			$('.manifest-search').val(ap.lastSearch)
			@search(ap.lastSearch)
			ap.lastSearch = false
		@initSelect2()
		@search()

	initSelect2: ->
		# Country Select
		year_select = $('#manifest-year-select')
		years = [
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

		type_select = $('#manifest-type-select')
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
			$('#manifest-year-select').select2('val', ['16'])
			$('#manifest-type-select').select2('val', ['360', 'connect'])
		, 100

	search: ->
		val = $('.manifest-search').val()
		clearTimeout(@timo)
		@timo = setTimeout ->
			years = $('#manifest-year-select').val()
			types = $('#manifest-type-select').val()
			ap.api 'get users', {search: val, years: years, types: types}, (rsp) ->
					html = ''
					for atn in rsp.users
						atn = new ap.User(atn)
						type = 'type-'+atn.get('ticket_type')
						user_name_row = if atn.get('user_name').length then atn.get('user_name') else 'Hasn\'t Setup Account'
						user_name_link = if atn.get('user_name').length then atn.get('user_name') else atn.get('hash')
						html += '<tr data-user="'+user_name_link+'" class="'+type+'">
							<td>
								<div class="manifest-avatar" style="background:url('+atn.get('pic')+')"></div>
								<span>'+atn.get('first_name')+' '+atn.get('last_name')+'</span>
								<div class="user_name">'+user_name_row+'</div>
							</td>
							<td>'+atn.get('email')+'</td>'
					$('#manifest-results').html(html)
					$('#manifest-start').hide()
					$('#manifests-results-shell').show()
			# else
			# 	$('#manifest-start').show()
			# 	$('#manifests-results-shell').hide()
		, 500
	row_click: (e) ->
		ap.lastSearch = $('.manifest-search').val()
		user = $(e.currentTarget).data('user')
		ap.navigate('admin/user/'+user)

	whenFinished: ->
		ap.lastSearch = $('.manifest-search').val()

