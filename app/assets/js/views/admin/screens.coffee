ap.Views.admin_screens = XView.extend
	messageTimo: 0

	events:
		'click .toggle-message': 'messageToggle_click'
		'click .do-toggle-message': 'doMessageToggle_click'
		'click #message-save-later': 'doMessageToggle_click'

	initialize: ->
		ap.api 'get screens', {}, (rsp) =>
			@message = rsp.message
			@options.out = _.template @options.out, @message
			@initRender()

	rendered: ->
		@initMessageActivation()

	initMessageActivation: ->
		console.log JSON.stringify(@message)
		if @message.activated == "yes"
			text = 'Message Active'
			clss = 'deactivate-message'
			action = 'Deactivate'
			$('#message-save-later').html("Change Message")
		else
			text = 'Message Inactive'
			clss = 'activate-message'
			action = 'Activate'
			$('#message-save-later').html("Save Message For Later")

		$('.display-shell').html('
			<div class="active-message">
				<h4>'+text+'</h4>
				<a href="#" class="'+clss+' toggle-message button waitable">'+action+' Message</a>
			</div>
		')
		$('.waitable').prop('disabled', false)

	messageToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		el.removeClass('toggle-message')
		el.addClass('do-toggle-message')
		if el.hasClass('deactivate-message')
			action = 'Deactivate'
		else
			action = 'Activate'
		$(el).html('Click Again to '+action)
		@ticketTimo =  setTimeout ->
			el.html(action+' Message')
			el.addClass('toggle-message')
			el.removeClass('do-toggle-message')
		, 1200

	doMessageToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		@message.title = $('#message-title').val()
		@message.message = $('#message-message').val()
		if el.hasClass 'do-toggle-message'
			clearTimeout(@messageTimo)
			if el.hasClass('deactivate-message')
				@message.activated = "no"
			else
				@message.activated = "yes"
		$('.waitable').prop('disabled', true).html('Please wait...')
		view = this
		ap.api 'put screens', @message, (rsp) =>
			view.initMessageActivation()

