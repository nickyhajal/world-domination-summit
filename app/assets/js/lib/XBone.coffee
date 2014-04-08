## 
 # Extended backbone view
 ##
window.XView = Backbone.View.extend
	out: ''
	defaults: 
		output: false
	initialize: ->
		@initRender()

	initRender: ->
		if @options
			@render @options.render

		if this.options.view?
			view = this.options.view
			sidebar = ap.template_options['pages_'+view]?.sidebar ? false
			if sidebar
				html = ap.templates['sidebar_'+sidebar]
				tk html
				$('#sidebar_shell').html html


	##
	 # Render now simple outputs in the channel
	 # we request - use @prepare() to template, etc
	 # then call render
	 ##
	render: (output_type)->
		html = @out
		if not html and @options.out?
			html = @options.out
		switch output_type
			when 'html'
				tmpEl = @el;
				@el = $('<div/>').html(html)
				@rendered()
				outEl = @el;
				@el = tmpEl
				return outEl.html()
			when 'replace'
				$(@el).html(html).scan()
			when 'append'
				$(@el).append(html).scan()
			when 'prepend'
				$(@el).prepend(html).scan()
		@rendered()
		if @options.onRender?
			@options.onRender()
	rendered: ()->
		# Child over-writes
	
##
 # Extended backbone model
 ##
window.XModel = Backbone.Model.extend()

##
 # Extended backbone collection
 ##
window.XCollection = Backbone.Collection.extend
	indexByCid: (cid) -> 	 
		for index, model of @models
			if +model.cid == +cid
				return index
		return false
	indexById: (id) -> 	 
		for index, model of @models
			if +model.id == +id
				return index
		return false
	getOrFetch: (id, cb) ->
		# Change this to
		# if get
		# then if where
		# then fetch
		if @get(id)
			cb(@get(id))
		else
			model = new @model(id)
			id.clean = true
			model.fetch
				data: id
				success: (fetched, rsp) =>
					@add fetched
					cb fetched
