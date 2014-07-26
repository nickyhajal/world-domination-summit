ap.Views.admin_screens = XView.extend
	messageTimo: 0
	screenResetTimo: 0

	events:
		'click .toggle-message': 'messageToggle_click'
		'click .do-toggle-message': 'doMessageToggle_click'
		'click #message-save-later': 'doMessageToggle_click'
		'click .toggle-screenreset': 'screenResetToggle_click'
		'click .do-toggle-screenreset': 'doScreenResetToggle_click'

	initialize: ->
		ap.api 'get screens', {}, (rsp) =>
			@message = rsp.message
			@options.out = _.template @options.out, @message
			@initRender()

	rendered: ->
		@initMessageActivation()
		@initScreenReset()

	initMessageActivation: ->
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

	initScreenReset: ->
		$('.screenreset-shell').html('
			<div class="screen-reset">
				<h4>Running into trouble?</h4>
				<a href="#" class="toggle-screenreset button">Reset the LCD screens</a>
			</div>
		')

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
		@messageTimo = setTimeout ->
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

	screenResetToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		el.removeClass('toggle-screenreset')
		el.addClass('do-toggle-screenreset')
		$(el).html('Click Again to Reset LCDs')
		@screenResetTimo = setTimeout ->
			el.html('Reset the LCD screens')
			el.removeClass('do-toggle-screenreset')
			el.addClass('toggle-screenreset')
		, 1200

	doScreenResetToggle_click: (e) ->
		e.preventDefault()
		el = $(e.currentTarget)
		view = this
		if el.hasClass 'do-toggle-screenreset'
			clearTimeout(@screenResetTimo)
			$(el).html('Resetting...').prop('disabled', true)
			now = new Date()
			ap.api 'post screens/reset', {lastResetUTC: new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds())).getTime()}, =>
				$(el).html('LCD screens reset!')
				setTimeout ->
					view.initScreenReset()
				, 1200

