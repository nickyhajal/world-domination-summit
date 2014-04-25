ap.Views.transfer = XView.extend

	initialize: ->
		@initRender()

	rendered: ->
		@initSelect2()

	###
		Use Select2 to have nice select boxes for the address fields
	###
	initSelect2: ->
		countries = []
		countries.push {id: country.alpha2, text: country.name} for country in ap.countries.all
		countryById = {}
		for c in countries
			countryById[c.id] = c

		$('#country-select').select2
			placeholder: "Country"
			data: countries
			initSelection: (el, cb) ->
				cb countryById[el.val()]
			width: '300px'
