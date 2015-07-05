ap.Views.admin_place = XView.extend
	events:
		'submit #admin-place-update': 'update'
	initialize: ->
		thePlace = false
		ap.api 'get places', {}, (rsp) =>
			for place in rsp.places
				if +place.place_id is +@options.extra
					thePlace = place
			@options.out = _.template @options.out, thePlace
			@place = thePlace
			@initRender()

	rendered: ->
		ap.api 'get place_types', {}, (rsp) =>
			data = []
			select = $('#place-type-select')
			for type in rsp.place_types
				data.push ({id: type.placetypeid, text: type.type_name})
			select.select2
				data: data
			select.select2('val', @place.place_type)

	update: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		btn = _.btn($('.button', el), 'Saving...', 'Saved!')
		form = el.formToJson()
		ap.api 'put place', form, (rsp) ->
			btn.finish()
			ap.navigate('admin/places')
