ap.Views.academy_purchase = XView.extend
	charging: false
	claiming: false
	card: false
	useExisting: false
	free_maxed: false
	giving: false
	newAccount: false
	names: []
	events:
		'click .cnct-cnct-account': 'showCreateAccount'
		'click .show-panel': 'showEvent'
		'click .done-button': 'done'
		'click .claim-academy': 'claim'
		'submit #login-form': 'login'
		'submit #purchase-form': 'purchase'
		'submit .give-ticket-form': 'giveTickets'
		'click .use-new-card': 'newCard'
		'click .use-existing-card': 'existingCard'

	initialize: ->
		@status = 'out'
		@updateRender()

	getCard: ->
		ap.api 'get user/card', {}, (rsp) =>
			if rsp.card? and rsp.card
				@useExisting = true
				@card = rsp.card
			else
				@useExisting = false
			@updateRender()

	updateRender: ->
		filler = {what: '', what_short: '', price: '', card_exp: '', card_type: 'visa', card_end: ''}
		if ap.activeAcademy
			filler = _.defaults ap.activeAcademy, filler
			if filler.what?
				filler.what_short = _.truncate(filler.what, 48)
		if @status == 'out'
			filler.price = '59'
		else
			filler.price = '29'
		if @card
			filler.card_exp = @card.exp_month + '/' +@card.exp_year
			filler.card_type = @card.brand
			filler.card_end = @card.last4
		@out = _.t 'parts_academy-purchase', filler
		@initRender()

	rendered: ->
		if @card
			$('body').addClass('has-card')
		@showFromStatus()
		if @status == 'free-maxed'
			$('.ac-free-full-alert').removeClass('hidden')
		else
			$('.ac-free-full-alert').addClass('hidden')

	showEvent: (e) ->
		$t = $(e.currentTarget)
		panel = $t.data('panel')
		@show(panel)

	show: (panel) ->
		$('.cc-error').hide()
		$('.modal-panel').hide()
		$('.modal-panel-ac-'+panel).show()
		if ap.me
			$('.if-no-user').hide()
		else
			$('.if-no-user').show()

	appeared: ->
		ac = ap.activeAcademy
		if ac.num_free >= ac.free_max
			@free_maxed = true
		@getCard()
		if ap.me? and ap.me and parseInt(ap.me.get('attending'+ap.yr)) is 1
			if parseInt(ap.me.get('academy')) > 0
					@status = 'claimed'
			else
				if @free_maxed
					@status = 'free-maxed'
				else
					@status = 'claim'
		else if ap.me? and ap.me
			@status = 'not-atn'
		else
			@status = 'out'
		@updateRender()
		Stripe.setPublishableKey(ap.stripe_pk);

	showFromStatus: ->
		if @status == 'claimed' or @status == 'not-atn' or @status == 'free-maxed'
			@show('buy')
		else if @status == 'claim'
			@show('free')
		else
			@show('start')

	newCard: (e) ->
		e.preventDefault()
		e.stopPropagation()
		$('.card-existing').hide()
		$('.card-new').show()
		@useExisting = false

	existingCard: (e) ->
		e.preventDefault()
		e.stopPropagation()
		$('.card-existing').show()
		$('.card-new').hide()
		@useExisting = true

	processing: (isProc = true) ->
		if isProc
			$('.cnct-process-shell').addClass('active')
		else
			@charging = false
			$('.cnct-process-shell').removeClass('active')

	purchase: (e) ->
		e.preventDefault()
		e.stopPropagation()
		return if @charging
		@charging = true
		$t = $(e.currentTarget)
		post = $t.formToJson()
		@processing()
		charge = =>
			post.event_id = ap.activeAcademy.event_id
			if @useExisting
				@doCharge(@card.hash, post)
			else
				Stripe.card.createToken $t, (status, rsp) =>
					if rsp.error
						$('.cc-error').show().html rsp.error.message
						@processing(false)
						$.scrollTo(0)
						setTimeout ->
							$('.cc-error').hide()
						, 10000
					else
						@doCharge(rsp.id, post)
		if ap.me
			charge()
		else
			post.login = true
			ap.api 'post user', _.omit(post, 'quantity'), (rsp) =>
				if rsp.existing?
					@processing(false)
					$('.cc-error').show().html 'That email is in our system. <a href="#" class="show-panel" data-panel="login">Click here to login.</a>'
					$.scrollTo(0)
				else
					ap.api 'get me', {}, (rsp) =>
						ap.login(rsp.me)
						charge()
	doCharge: (card_id, purchase_data) ->
		ap.api 'post product/charge', {card_id: card_id, code: 'academy', purchase_data: purchase_data}, (rsp) =>
			if (rsp.declined? and rsp.declined)
				$('.cc-error').show().html "Your card was declined. Please double check your details or try another card."
				@processing(false)
				$.scrollTo(0)
				setTimeout ->
					$('.cc-error').hide()
				, 10000
			else
				@processing(false)
				@show('purchased')
				@finishButton()

	claim: (e) ->
		$t = $(e.currentTarget)
		e.preventDefault()
		e.stopPropagation()
		$t.html('Claiming...')
		ap.api 'post event/claim-academy', {event_id: ap.activeAcademy.event_id}, (rsp) =>
			@show('claimed')
			@finishButton()

	finishButton: ->
		$('.rsvp-button').html('You\'re Attending!').addClass('attending')

	login: (e) ->
		e.preventDefault()
		$t = $(e.currentTarget)
		post = $t.formToJson()
		ap.api 'post user/login', post, (rsp) =>
			if rsp.loggedin and rsp.me?
				ap.login rsp.me
				@show('buy')
			else
				$('.login-error').show()
				setTimeout ->
					$('.login-error').hide()
				, 10000

