## 
 # Extended backbone view
 ##
window.XView = Backbone.View.extend
	out: ''
	defaults: 
		output: false
	initialize: (options) ->
		view = this.options.view
		sidebar = ap.template_options['pages_'+view]?.sidebar ? false
		if ap.template_options['pages_'+view]?
			for opt_name,val of ap.template_options['pages_'+view]
				this.options[opt_name] = val
		@initRender()

	initRender: ->
		if @options
			@render @options.render
		if @options.view?
			view = @options.view
		if @options.sidebar?
			html = ap.templates['sidebar_'+@options.sidebar]
			if @options.sidebar_filler?
				html = _.template html, @options.sidebar_filler
			$('#sidebar-shell').html(html).show().scan()
		else
			$('#sidebar-shell').hide()

	post: (html) ->
		shell = $('<div/>').html(html)
		icon = @options.icon ? 'globe'
		$('#page_content', shell).addClass('corner-icon-'+icon)
		if @options.photo_head?
			shell = @renderPhotoHeader(shell)
		return shell.html()

	renderPhotoHeader: (shell) ->
		main_content = $('#page_content', shell).html()
		content = $('#page_content', shell)
		photos = '
			<a href="#" class="photo-head-prev"></a>
			<a href="#" class="photo-head-next"></a>
		'
		active = true
		for photo in @options.photo_head.split(',')
			photos += '<img src="'+photo+'"'
			if active
				active = false
				photos += ' class="photo-head-active"'
			photos += '/>'
		main_content = '
			<div class="photo-header">'+photos+'</div>
			<div class="lifted-content">'+main_content+'</div>
		'
		content.html(main_content)

		el = $(@el)
		el.data('on-photo', 0)

		goToPhoto = (dir) ->
			$t = $(this)
			$c = $t.closest('#page_content')
			inx = el.data('on-photo') + (1 * dir)
			num_photos = $('img', el).length
			if (inx < 0)
				inx = num_photos - 1
			if (inx + 1 > num_photos)
				inx = 0
			$('.photo-head-active', $c).removeClass('photo-head-active')
			$('.photo-header img', $c).eq(inx).addClass('photo-head-active')
			el.data('on-photo', inx)
			return false

		$(@el)
			.on('click', '.photo-head-next', -> return goToPhoto.call(this, 1))
			.on('click', '.photo-head-prev', -> return goToPhoto.call(this, -1))

		return shell


	##
	 # Render now simple outputs in the channel
	 # we request - use @prepare() to template, etc
	 # then call render
	 ##
	render: (output_type)->
		html = @out
		if not html and @options.out?
			html = @options.out
		html = @post(html)
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
	finish: ->
		if @whenFinished?
			@whenFinished()
		@unbind()
	rendered: ()->
		# Child over-writes
	
###
	Extended backbone model
###
window.XModel = Backbone.Model.extend
	changedSinceSave: {}
	trackChangesSinceSave: ->
		@on 'change', (obj) =>
			for key,val of obj.changed
				@changedSinceSave[key] = val
			if @idAttribute?
				@changedSinceSave[@idAttribute] = @get(@idAttribute)
		@on 'sync', (obj) =>
			@changedSinceSave = {}


###
	Extended backbone collection
###
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
