ap.Views.admin_add_attendee = XView.extend
	events:
		'submit #admin-add-user': 'addUser_submit'
	initialize: ->
		@initRender()
	rendered: ->
		@initSelect2()
	addUser_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		post['attending'+ap.yr] = '1'
		post.t = true;
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		ap.api 'post user', post, (rsp) ->
			btn.finish()
			setTimeout ->
				ap.lastSearch = post.first_name+' '+post.last_name
				ap.navigate('admin/manifest')
			, 1200
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
