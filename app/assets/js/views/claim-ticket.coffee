ap.Views.claim_ticket = XView.extend
	events:
		'click .ticket-purchase': 'openPurchase'

	initialize: ->
		@initTemplateOptions()
		@initRender()
	rendered: ->
		@stripe = StripeCheckout.configure
			key: ap.stripe_pk
			image: 'http://worlddominationsummit.com/images/default-avatar.png'
			locale: 'auto'
			token: (token) =>
				@showProcessing()
				ap.api 'post charge/ticket', {token: token.id}, (rsp) ->
					if (rsp.charge_success? and rsp.ticket?)
						ap.navigate('mission-accomplished/'+rsp.ticket.hash)
					else if rsp.charge_success?
						tk 'Charged, not ticketed'
					else
						tk 'Not charged or ticketed'



		$(window).on 'popstate', =>
			@stripe.close();

	showProcessing: ->

	openPurchase: (e) ->
		e.preventDefault();
		@stripe.open
			name: 'WDS 2018'
			description: 'Main Stage Ticket'
			amount: 54700
			panelLabel: "Get Your Ticket!"
			shippingAddress: false
			allowRememberMe: false
			billingAddress: true
