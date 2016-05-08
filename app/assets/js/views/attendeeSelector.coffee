ap.Views.AttendeeSelector = XView.extend
	selected: []
	bios: {}
	events:
		'click .attendee-selector-add': 'addAtn'
		'click .attendee-selector-edit-bio': 'editBio'
		'click .attendee-selector-remove': 'removeAtn'
	initialize: ->
		tk @options.filler
		@selected = []
		@options.out = _.t('parts_attendee-selector', @options.filler)
		@initRender()
	rendered: ->
		inp = $('.attendee-selector-inp')
		ap.Modals.add('attendee-selector')
		ap.Modals.add('attendee-bio')
		inp.attr('name', @options.name)
		ids = inp.val().split(',')
		for id in ids
			if id? and ap.Users.get(id)
				@selected.push ap.Users.get(id)
		if ap.bios?.length
			@bios = JSON.parse(ap.bios)
		$('.attendee-selector-bios').val(JSON.stringify(@bios))
		@syncToSelected()
	addAtn: (e) ->
		e.stopPropagation()
		e.preventDefault()
		ap.Modals.open('attendee-selector')
		ap.attendeeSelectionCb = @onSelect.bind(this)
	removeAtn: (e) ->
		e.stopPropagation()
		e.preventDefault()
		$t = $(e.currentTarget)
		user_id = $t.parent().data('user_id')
		tmp = []
		for user in @selected
			if user.get('user_id') != user_id
				tmp.push user
		@selected = tmp
		@syncToSelected()
	editBio: (e) ->
		e.stopPropagation()
		e.preventDefault()
		$t = $(e.currentTarget)
		user_id = $t.parent().data('user_id')
		ap.currBioUser = user_id
		ap.currBio = @bios[user_id] ? ''
		ap.Modals.open('attendee-bio')
		ap.bioCb = @onBioChange.bind(this)
	onSelect: (user) ->
		unless _.contains(@selected, user)
			@selected.push(user)
		@syncToSelected()
	onBioChange: (bio) ->
		@bios[ap.currBioUser] = bio
		$('.attendee-selector-bios').val(JSON.stringify(@bios))
		ap.Modals.close()
	syncToSelected: ->
		ids = []
		html = ''
		for u in @selected
			name = u.get('first_name')+' '+u.get('last_name')
			ids.push(u.get('user_id'))
			html += '<div class="attendee-selector-selected-row" data-user_id="'+u.get('user_id')+'">
				<a href="#" class="attendee-selector-remove">x</a>
				<a href="#" class="attendee-selector-edit-bio">Bio</a>
				'+name+'
			</div>'
		$('.attendee-selector-inp').val(ids.join(','))
		$('.attendee-selector-selected').html(html)
		ap.Modals.close()

