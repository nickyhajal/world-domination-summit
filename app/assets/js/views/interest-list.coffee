ap.Views.InterestList = XView.extend
	events: 
		'click .interest-button': 'addInterest'
		'click .interest-remove-button': 'removeInterest'
	initialize: ->
		@selected = []
		@$selected = $('.interests-selected', @el)
		@interestById = {}
		@interestIds = []
		for interest in ap.interests
			@interestById[interest.interest_id] = new ap.Interest(interest)
			@interestIds.push interest.interest_id

		@render()
		
	selectedInterests: ->
		return JSON.parse(ap.me.get('interests'))

	setInterests: (interests) ->
		ap.me.set('interests', JSON.stringify(interests))

	render: ->
		html = '
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
				<label>Your Interests</label>
			'
			for interest in selected
				interest = @interestById[interest].set('classes', 'interest-remove-button')
				html += _.t('parts_interest-button', interest.attributes)
		html += '<div class="clear"></div>'
		$(@el).html html

	addInterest: (e) ->
		$t = $(this)
		e.preventDefault()
		interest_id = $(e.currentTarget).data('interest_id')
		selected = @selectedInterests()
		selected.push interest_id
		@setInterests(selected)
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
		ap.api 'delete user/interest', {interest_id: interest_id}
		@setInterests(tmp)
		@render()
