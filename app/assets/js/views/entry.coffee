ap.Views.Entry = XView.extend
	initialize: ->
		@prepare()
		@initRender()
	prepare: ->
		tpl = ap.templates['parts_entry']
		filler = @options.entry.attributes
		tpl = _.template tpl, filler
		@out = tpl
