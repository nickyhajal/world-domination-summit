ap.Views.admin_add_place = XView.extend
	events:
		'submit #admin-add-place': 'add_submit'
	initialize: ->
		ap.api 'get place_types', {}, (rsp) ->
			data = []
			select = $('#place-type-select')
			for type in rsp.place_types
				data.push ({id: type.placetypeid, text: type.type_name})
			select.select2
				data: data


		@initRender()
	add_submit: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		post = el.formToJson()
		btn = _.btn($('.button', el), 'Adding...', 'Added!')
		ap.api 'post racetask', post, (rsp) ->
			btn.finish()
			setTimeout ->
				ap.navigate('admin/racetasks')
			, 200