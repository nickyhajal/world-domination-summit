
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
				image: 'https://worlddominationsummit.com/images/default-avatar.png'
				locale: 'auto'
				token: (token) =>
					data = $('.purchase-data').formToJson()
					@showProcessing()
					ap.api 'post product/charge', {card_id: token.id, code: @product.code, purchase_data: data}, (rsp) =>
						@options.onResponse(rsp)
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
		email = (if ap.me? then _.trim(ap.me.get('email')) else null)
		@stripe.open
			name: @product.name
			description: @product.descr
			amount: @product.cost
			panelLabel: @product.purch_cta
			shippingAddress: false
			allowRememberMe: false
			email: email
			billingAddress: if @options.billing_addr then true else false

	whenFinished: ->
		clearTimeout(@remainTimo)
		$('.ticket-purchase', '#sidebar').off 'click'
