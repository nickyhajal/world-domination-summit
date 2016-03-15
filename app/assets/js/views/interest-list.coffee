ap.Views.InterestList = XView.extend
	initd: false
	events:
		'click .interest-button': 'addInterest'
		'click .interest-remove-button': 'removeInterest'
	initialize: ->
		_.whenReady 'assets', =>
			@context = @options.context
			@selected = []
			@$selected = $('.interests-selected', @el)
			@interestById = {}
			@interestIds = []
			for interest in ap.interests
				@interestById[interest.interest_id] = new ap.Interest(interest)
				@interestIds.push interest.interest_id

			@render()
			if @context is 'generic'
				@input = $('<input/>').attr('name', 'interests').attr('type', 'hidden')
				$(@el).before(@input)

	selectedInterests: ->
		if @context is 'user'
			return ap.me.get('interests')
		else
			return @selected

	setInterests: (interests) ->
		if @context is 'user'
			ap.me.set('interests', interests)
		else if @context is 'generic'
			val = interests.join(',')
			@selected = interests
			@input.val(val)

	render: ->
		html = ''
		if @context is 'generic'
			label = 'Selected Interests'
		else if @context is 'user'
			label = 'Your Interests'
		html += '
			<label>Select Interests Below</label>
		'
		selected = @selectedInterests()
		unselected = _.difference(@interestIds, selected)
		for interest in unselected
			interest = @interestById[interest].set('classes', 'interest-button')
			html += _.t('parts_interest-button', interest.attributes)
		if selected.length
			html += '
				<div class="clear"></div>
				<label>'+label+'</label>
			'
			for interest in selected
				interest = @interestById[interest].set('classes', 'interest-remove-button')
				html += _.t('parts_interest-button', interest.attributes)
		html += '<div class="clear"></div>'
		$(@el).html html
		if @initd
			@initd = true
			XHook.trigger('interests-updated')

	addInterest: (e) ->
		$t = $(this)
		e.preventDefault()
		interest_id = $(e.currentTarget).data('interest_id')
		selected = @selectedInterests()
		selected.push interest_id
		@setInterests(selected)

		if @context is 'user'
			ap.api 'post user/interest', {interest_id: interest_id}
		@render()

	removeInterest: (e) ->
		$t = $(this)
		e.preventDefault()
		interest_id = $(e.currentTarget).data('interest_id')
		selected = @selectedInterests()
		tmp = []
		for interest in selected
			if interest isnt interest_id
				tmp.push interest
		if @context is 'user'
			ap.api 'delete user/interest', {interest_id: interest_id}
		@setInterests(tmp)
		@render()
