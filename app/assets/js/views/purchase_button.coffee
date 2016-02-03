ap.Views.purchase_button = XView.extend
	remainTimo: 0
	product: false
	events:
		'click .purchase-btn': 'openPurchase'

	initialize: ->
		@out = @options.out
		if @options.product
			@product = @options.product
			@initRender()
		else
			ap.api 'get product', {code: @options.code}, (rsp) =>
				if rsp.product
					@product = rsp.product
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
					data = $('.purchase-data').formToJson()
					@showProcessing()
					ap.api 'post product/charge', {card_id: token.id, code: @product.code, purchase_data: data}, (rsp) ->
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
		if @options.checkAvailability
			ap.api 'get product/availability', {code: @options.code}, (rsp) ->
				# TODO: Check rsp.active
				# TODO: Check rsp.remaining
				$('.tickets-remaining-num').text(rsp.num)
				$('.tickets-remaining-shell').show()
			@remainTimo = setTimeout @getRemainingTickets, 5000

	openPurchase: (e) ->
		e.preventDefault();
		@stripe.open
			name: @product.name
			description: @product.descr
			amount: @product.cost
			panelLabel: @product.purch_cta
			shippingAddress: false
			allowRememberMe: false
			billingAddress: @options.billing_addr

	whenFinished: ->
		clearTimeout(@remainTimo)
		$('.ticket-purchase', '#sidebar').off 'click'
