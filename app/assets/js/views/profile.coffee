###

	The view someone sees the very first time
	they go to the WDS site

	This will appear until their 'intro' count
	is above the number of welcome tabs

###

ap.Views.profile = XView.extend

	initialize: ->

		$("head").append("<META NAME='robots' id='noindexmeta' CONTENT='noindex'>")
		@options.sidebar = 'profile'
		@options.sidebar_filler = @options.attendee.attributes
		@renderInterests()
		@renderQuestions()
		@renderConnect()
		@options.attendee.set
			pic: @options.attendee.getPic(400)
		@options.out = _.template @options.out, @options.attendee.attributes
		@options.out = _.template @options.out, @options.attendee.attributes
		@initRender()
		self = this

	rendered: ->
		setTimeout =>
			@renderMap()
		, 5
		@hideEmptySections()
		if ap.me?.get('has_pw')? and ap.me.get('has_pw')
			$('#tab-panel-the-basics .form-section').eq(1).hide()


	renderQuestions: ->
		questions = [
			'Why did you travel <span class="ceil">{{ distance }}</span> miles to the World Domination Summit'
			'What are you excited about these days?'
			'What\'s your super-power?'
			'What is your goal for WDS 2016?'
			'What\'s your favorite song?'
			'What\'s your favorite treat?'
			'What\'s your favorite beverage?'
			'What\'s your favorite quote?'
			'What are you looking forward to during your time in Portland?'
		]
		count = 0
		html = ''
		for answer in JSON.parse(@options.attendee.get('answers'))
			html += '<div class="attendee-question-shell">'
			html += '<div class="question">'+questions[answer.question_id - 1]+'</div><div class="answer">'+answer.answer+'</div>'
			html += '</div>'
			count += 1
		html += '<div class="clear"></div>'
		@options.attendee.set
			questions: html

	renderConnect: ->
		atn = @options.attendee
		html = ''

		# Site with all prefixes removed
		if atn.get('site')?.length
			site = atn.get('site').replace('http://', '').toLowerCase()
			html += '<a target="_blank" href="http://'+site+'">'+site.replace('www.', '')+'</a>'

		# Twitter, removing an at sign if it gets in there
		if atn.get('twitter')?.length
			twit = atn.get('twitter').replace('@', '').toLowerCase()
			html += '<a target="_blank" href="http://twitter.com/'+twit+'">@'+twit+'</a>'

		# Facebook has a bunch of processing to either get a username
		# or detect an email/full name and forward to a search link instead
		if atn.get('facebook')?.length
			fb = atn.get('facebook').toLowerCase()
			if fb.indexOf('/pages/') < 0 and fb.indexOf('profile.php') < 0
				fb = fb.split('/')
				fb = fb[fb.length - 1].split('?')
				fb = fb[0]
				at = fb.indexOf('@')
				if at is 0
					fb.str_replace('@', '')
				if at > 0 or fb.indexOf(' ') > 0
					link = 'https://facebook.com/search/results.php?type=users&q='+fb
				else
					link = 'https://facebook.com/'+fb
				fb = 'fb.com/'+fb
				html += '<a target="_blank" href="'+link+'">'+fb+'</a>'

		# instagram is like twitter
		if atn.get('instagram')?.length
			ig = atn.get('instagram').replace('@', '').toLowerCase()
			html += '<a target="_blank" href="http://instagram.com/'+ig+'">ig.com/'+ig+'</a>'

		@options.attendee.set
			connect: html

	renderInterests: ->
		html = ''
		_.whenReady 'assets', =>
			for interest in @options.attendee.get('interests')
				interest = ap.Interests.get(interest)
				html += '<a href="/group/'+_.slugify(interest.get('interest'))+'" class="interest-button">'+interest.get('interest')+'</a>'
			html += '<div class="clear"></div>'
			@options.attendee.set
				interests: html

	renderMap: ->
		_.whenReady 'googlemaps', =>
			attendee = @options.attendee.attributes
			profile_map_el = document.getElementById('attendee-profile-map')
			mapOptions =
				center: new google.maps.LatLng(attendee.lat, attendee.lon)
				zoom: 8
				scrollwheel: false
				disableDefaultUI: true
			profile_map = new google.maps.Map(profile_map_el, mapOptions)

	hideEmptySections: ->
		if not $('.attendee-question-shell', $(@el)).length
			$('#profile-questions-shell').hide()
		if not $('.interest-button', $(@el)).length
			$('#profile-interested-in-shell').hide()
		setTimeout =>
			if not $('.dispatch-content-section', $(@el)).length
				$('#profile-dispatch-shell').hide()
		, 1000

	syncAvatar: ->
		if ap.me.get('pic')?
			$('.current-avatar').show()
			$('.avatar-shell').empty().append $('<img/>').attr('src', ap.me.get('pic').replace('_normal', ''))

	tablet: ->
		width = $(window).width(true) - (179)
		$('#attendee-profile-map').css('width', _.x(width))
		$('.attendee-avatar').css('height', '')
		$('.button', '#profile-controls').css('width', _.x((width-90)/2))

	desktop: ->
		$('#attendee-profile-map').css('width', '')
		$('.attendee-avatar').css('height', '')

	phone: ->
		av = $('.attendee-avatar')
		av.css('height', _.x(av.width()))
		$('.button', '#profile-controls').css('width', '')

	whenFinished: ->
		$("#noindexmeta").remove()