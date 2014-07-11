ap.Views.notes = XView.extend
	events: 
		'submit #note-form': 'submitNote'
	initialize: ->
		_.whenReady 'users', =>
			@options.user = ap.Users.get(@options.user_id)
			@options.sidebar = 'notes'
			@options.sidebar_filler = @options.user
			@options.out = _.template @options.out, @options.user.attributes
			@initRender()

	rendered: ->
		@renderNotes()

	renderNotes: ->
		ap.api 'get user/notes', {about_id: @options.user_id}, (rsp) =>
			html = ''
			if rsp.notes.length
				for note in rsp.notes
					time = moment(note.created_at).format('MMMM Do YYYY, h:mm:ss a')
					html += '<div class="note-shell">
						'+note.note+'
						<div class="note-time">'+time+'</div>
					</div>'
			else
				first_name = @options.user.get('first_name')
				html += '<div class="note-empty">You haven\'t added any notes about '+first_name+' yet!</div>'
			$('#notes-shell').html(html)

	submitNote: (e) ->
		e.preventDefault()
		note = $('#note-input').val()
		btn = _.btn($('.button', '#note-form'), 'Saving...', 'Saved!')
		ap.api 'post user/note', {about_id: @options.user_id, note: note}, (rsp) =>
			btn.finish()
			@renderNotes()

