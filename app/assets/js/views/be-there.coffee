ap.Views.be_there = XView.extend
	remainTimo: 0
	events:
		'click .ticket-purchase': 'openPurchase'

	initialize: ->
		@initTemplateOptions()
		@initRender()

	rendered: ->
		setTimeout =>
			$('.ticket-purchase', '#sidebar').on 'click', (e) =>
				@openPurchase(e)
		, 500
		@setupStripe()
		@getRemainingTickets()

	setupStripe: ->
		if StripeCheckout?
			@stripe = StripeCheckout.configure
				key: ap.stripe_pk
				image: 'http://worlddominationsummit.com/images/default-avatar.png'
				locale: 'auto'
				token: (token) =>
					@showProcessing()
					ap.api 'post ticket/charge', {token: token.id}, (rsp) ->
						if (rsp.charge_success? and rsp.ticket?)
							ap.tbyh = {} if not ap.tbyh?
							ticket = rsp.ticket
							ticket.meta_data = JSON.parse(ticket.meta_data)
							ap.tbyh[ticket.hash] = ticket
							ap.navigate('mission-accomplished/'+rsp.ticket.hash)
							$('.payment-processing').hide()
						else if rsp.charge_success?
							tk 'Charged, not ticketed'
						else
							tk 'Not charged or ticketed'
			$(window).on 'popstate', =>
				@stripe.close();
		else
			setTimeout =>
				@setupStripe()
			, 500

	showProcessing: ->
		$('.payment-processing').fadeIn()

	getRemainingTickets: ->
		ap.api 'get ticket/availability', {}, (rsp) ->
			$('.tickets-remaining-num').text(rsp.num)
			$('.tickets-remaining-shell').show()
		@remainTimo = setTimeout @getRemainingTickets, 5000

	openPurchase: (e) ->
		e.preventDefault();
		@stripe.open
			name: 'WDS 2016'
			description: 'Main Stage Ticket'
			amount: 54700
			panelLabel: "Get Your Ticket!"
			shippingAddress: false
			allowRememberMe: false
			billingAddress: true

	whenFinished: ->
		clearTimeout(@remainTimo)
		$('.ticket-purchase', '#sidebar').off 'click'
