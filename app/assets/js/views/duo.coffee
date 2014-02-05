ap.Views.duo = XView.extend
	name: 'duo'
	events: 
		'keyup document': 'keyWatch'
		'click #write-save-button': 'triggerSave'
		'click #write-save-button .dropdown-options span': 'changeStatus'
	autoSaveTimo: 0
	resizeTimo: 0
	statsTimo: 0
	saving: false
	lastSave: false
	lastSaveTime: false
	entry: false
	
	rendered: ->
		duo = @options.duo
		with_user = new ap.User(duo.get('with_user'))
		$('#content_shell').addClass("no-page")
		$('.with_name').html(with_user.get('first_name'))
		@initTinyMCE()
		@initEntry()
		@renderEntries()
		
	initEntry: ->
		duo = @options.duo
		@entry = new ap.Entry()
		if duo.get('unfinished')
			@entry.set duo.get('unfinished')
			@editor.setContent(@entry.get('entry_text'))
			@lastSave = @editor.getContent()
			@updateStats()
		@syncEntryStatus()

	renderEntries: ->
		duo = @options.duo
		$es = $('#entries-shell').empty()
		entries = @options.duo.get('entries')
		tk entries
		if entries and entries.length
			for entry in entries
				entry.duo = duo
				entry_el = new ap.Views.Entry
					el: $('#entries-shell')
					render: 'append'
					entry: new ap.Entry(entry)
		else
			$es.html '<div id="timeline-empty-message">No Entries - yet!</div>'

	initTinyMCE: ->
		@tinymceStart = '<p>Start typing here to create an entry.</p>'
		@tinymceStartH = 86
		self = this
		tinymce.init
			selector: "textarea"
			skin_url: '/assets/css/tinymce'
			toolbar: 'undo redo | bold italic underline strikethrough | bullist numlist'
			menubar: false
			statusbar: false
			setup: (ed) ->
				ed.on 'PreInit', () ->
					window.wtf = ed
					doc = ed.getDoc()
					jscript = "(function() {var config = {kitId: 'acm5sii'}; var d = false; var tk = document.createElement('script'); tk.src = '//use.typekit.net/' + config.kitId + '.js'; tk.type = 'text/javascript'; tk.async = 'true'; tk.onload = tk.onreadystatechange = function() {var rs = this.readyState; if (d || rs && rs != 'complete' && rs != 'loaded') return; d = true; try { Typekit.load(config); } catch (e) {} }; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(tk, s); })();"
					script = doc.createElement('script')
					script.type = 'text/javascript'
					script.appendChild(doc.createTextNode(jscript))
					doc.getElementsByTagName('head')[0].appendChild(script)
					$('head',  doc).append('
					    <style type="text/css">
					    	body  {
						    	font-family: rosario;
							    color:    rgb(129, 123, 115);
						    }
						</style>
					')
					$(doc).keydown( (e) => self.keyWatch(e, true))
				ed.on 'focus', ->
					clearTimeout(self.resizeTimo)
					if self.editor.getContent() is self.tinymceStart
						self.editor.setContent('')
					tinymce.editors.mce_0.theme.resizeTo(null, 500)
				ed.on 'blur', ->
					editor = self.editor
					editor.save()
					self.resizeTimo = setTimeout ->
						editor.theme.resizeTo(null, self.tinymceStartH)
						$('#mce_0_ifr').css('height', self.tinymceStartH+'px')
						if editor.getContent() is ''
							editor.setContent(self.tinymceStart)
					, 100
				ed.on 'init', ->
					setTimeout ->
						$('#mce_0_ifr').css('height', self.tinymceStartH+'px')
					, 1
		@editor = tinymce.editors.mce_0
		@editor.on('saveContent', (c) => @saveContent(c))
		@editor.setContent(@tinymceStart)
		@editor.theme.resizeTo(null, @tinymceStartH)
		$(document).keydown( (e) => @keyWatch(e))
					

	syncEntryStatus: ->
		$('#write-save-button .dropdown-options span').css('display', 'block')
		if +@entry.get('public')
			$('span[data-option="public"]').css('display', 'none')
		else
			$('span[data-option="draft"]').css('display', 'none')
		$('#write-save-button .button-text').html('Save '+@entry.getStatusString())

	updateStats: ->
		clearTimeout @statsTimo
		wc = @editor.getContent().replace(/<[^>]*>/g, "").replace(/&nbsp;/g, "").replace(/\n\n/g, "\n").split(/[\n ]/).length
		if wc > 2
			if @lastSaveTime
				time = @lastSaveTime
			else if @entry.get('updated_at')
				time = moment.utc((@entry.get('updated_at')).replace('Z', '')).valueOf()
			else 
				time = moment.utc().valueOf()
			time = _.nicetime(time, false, 5)
			$('#post-stats').html('Your '+wc+' words were last saved ' + time)
			@statsTimo = setTimeout =>
				@updateStats()
			, 60000
		else
			$('#post-stats').html('')

	changeStatus: (e) ->
		$t = $(e.currentTarget)
		status = if $t.data('option') is 'public' then 1 else 0
		@entry.save
			public: status

		#Success
		, 
			success: (model, rsp) =>
				if status
					ap.Notify.now
						msg: 'Your entry was posted!'
						expire: 5
				@syncEntryStatus()
				@updateDuo()

	saveContent: (c) ->
		if not @saving and @editor.getContent().length and @editor.getContent() isnt @tinymceStart and @lastSave isnt @editor.getContent()
			@saving = true
			btn = $('#write-save-button .button-text')
			btn.html('Saving...')
			@entry.save
				entry_text: c.content
				duoid: @options.duo.get('duoid')
			, 
				success: (model, rsp) =>
					btn.html 'Saved!'
					setTimeout =>
						@syncEntryStatus()
					, 750
					@lastSave = c.content
					@lastSaveTime = new Date()
					@saving = false
					@updateStats()
					@updateDuo()

	updateDuo: ->
		duo = @options.duo
		ap.api 'get duo', 
			duoid: duo.get('duoid')
			inc_entries: true
		, (rsp) =>
			@options.duo = new ap.Duo(rsp.duo)
			@renderEntries()

	triggerSave: ->
		@editor.save()
		return false

	keyWatch: (e, saveWatch = false) ->
		if saveWatch
			clearTimeout @autoSaveTimo
			@autoSaveTimo = setTimeout =>
				@triggerSave()
			, 1000
		@updateStats()
		if ap.currentView.name? and ap.currentView.name is 'duo'
			if e.keyCode is 83 and e.metaKey
				@triggerSave()
				e.stopPropagation()
				return false
