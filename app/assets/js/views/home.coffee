VIMEO_ID = '151533965'

ap.Views.home = XView.extend
	initialize: ->
		@initRender()
	rendered: ->
		wall.init()
	whenFinished: ->
		$(window).off('scroll', wall.scroll)

window.wall =

	# Variables
	used_content: {}
	block_tpls: {}
	tpls: []
	contByType: {}
	block_data: {}

	# Methods
	init: ->
		@initSafari()
		@extendMaps()
		$.scrollTo(0)
		wall.$el = $('#waterfall')
		wall.$q = $('#wall-queue')
		wall.drawnHeight = 0
		$(window).on('scroll', @loadMoreContentIfWeScrolledDownEnough)
		_.whenReady 'assets', =>
			@loadContent =>
				@fillContent($('.wall-section'))
				@generateWallPanels()
				setTimeout =>
					@reloadEveryFiveMinutes()
				, 1000 * 60 * 1
			@loadTpls()
		$('body')
			.on('click', '.wall-content-type-flickr_stream', wall.showBiggerPhoto)
			.on('click', '#video', wall.showVideo)
			.on('click', '#reg-army', wall.showArmy)

		@widths = [0, 990, 976, 990, 990]
		wall.zoomFactor = 1
		url_params = @urlParams()
		if url_params['screenmode']=='1'
			@screenMode = 1
			now = new Date()
			@startedAtUTC = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(),  now.getUTCHours(), now.getUTCMinutes(), now.getUTCSeconds())).getTime()
			@checkForReset()
			_.whenReady 'firstpanel', =>
				if url_params['delay']?
					@autoScrollDelay = url_params['delay']
				else
					@autoScrollDelay = 100
				@initScreenMode()
		else
			@screenMode = 0

	addScreenCss: ->
		css = '<style type="text/css">
			#waterfall {
				top: 0 !important;
				height: 0;
				width: 5850px;
				transition: left 1s linear;
			}
			.wall-section {
				float: left;
				width: 990px;
				clear: none !important;
			}
			div.tpl-4 {
			    width: 990px;
			}
		</style>'
		$('body').append(css)

	checkForReset: ->
		ap.api 'get screens/reset', {}, (rsp) ->
			if rsp.lastResetUTC?
				if rsp.lastResetUTC.lastResetUTC > wall.startedAtUTC
					location.reload(true)
		setTimeout =>
			wall.checkForReset()
		, 50000000


	urlParams: ->
		urlParams = Array()

		pageUrl = window.location.search.substring(1)
		urlVariables = pageUrl.split('&')
		for variable in urlVariables
			param = variable.split('=')
			urlParams[param[0]] = param[1]
		urlParams

	reloadEveryFiveMinutes: ->
		@loadContent =>
			setTimeout =>
				@reloadEveryFiveMinutes()
			, 1000 * 60 * 1

	initScreenMode: ->
		hideMe = ['#top-nav', '#notifications', '#main-header', '#header-title', '.tpl-0', '#video-shell', 'footer']
		for el in hideMe
			$(el).toggle()
		#$('*').css('cursor', 'none')

		@scaleForScreenMode()

		$(window).resize =>
			@scaleForScreenMode()
			if ($("#home-screen-overlay").length)
				$("#home-screen-overlay").css("width", $(window).width())
							 .css('height', $(window).height())

		@autoScroll()
		@screenMessage()
		@addScreenCss()

	emptyDivsNoLongerVisible: ->
		$('#waterfall').find('.wall-section.slated-for-empty').removeClass('slated-for-empty').addClass('emptied').each ->
			$el = $(this)
			setTimeout =>
				$el.empty()
			, 0
		$('#waterfall').find('.wall-section.will-be-slated-next-round').removeClass('will-be-slated-next-round').addClass('slated-for-empty')
		$('#waterfall').find('.wall-section:not(.will-be-slated-next-round):not(.slated-for-empty):not(.emptied)').addClass('will-be-slated-next-round')


	# Will load more content if we scroll down low enough
	loadMoreContentIfWeScrolledDownEnough: ->
		_.whenReady 'firstpanel', =>
			wall = window.wall
			if wall.zoomFactor?
				if $(window).scrollTop() > ($(document).height() - (4 * $(window).height()))
					wall.$el.css('height', Math.max($(window).scrollTop() + 4 * $(window).height(), wall.$el.height()) + 'px')
					wall.displayPanels()
					if wall.screenMode == 1
						wall.emptyDivsNoLongerVisible()

	loadMoreContentIfWeScrolledLeftEnough: ->
		_.whenReady 'firstpanel', =>
			wall = window.wall
			if wall.zoomFactor?
				wall.displayPanels()
				# left = parseInt(wall.$el.css('left'))
				# # width = wall.$el.width()
				# width = wall.drawnHeight
				# # tk 'LEFT: '+left
				# # tk 'WIDTH: '+ width
				# if left > (width - (4 * $(window).width()))
				# 	# tk '____redraw'
				# 	# tk Math.max(Math.abs(left) + 4 * $(window).width())
				# 	wall.$el.css('width', (Math.max(Math.abs(left) + $(window).width(), 2000)) + 'px')
					# if wall.screenMode == 1
					# 	wall.emptyDivsNoLongerVisible()


	scaleForScreenMode: ->
		_.whenReady 'firstpanel', =>
			# return false
			viewportSize = $(window).height()
			unless @originalContentainerSize?
				@originalContentainerSize = 782
			@zoomFactor = viewportSize / @originalContentainerSize
			# tk 'ZOOM:'
			# tk @originalContentainerSize

			$('#waterfall').css('transform', 'scale(' + @zoomFactor + ')')
				       .css('-moz-transform', 'scale(' + @zoomFactor + ')')
				       .css('-ms-transform', 'scale(' + @zoomFactor + ')')
				       .css('-o-transform', 'scale(' + @zoomFactor + ')')
				       .css('-webkit-transform', 'scale(' + @zoomFactor + ')')
				       .css('left', (-600 * @zoomFactor) + 'px')

			$('body').css('overflow', 'hidden')

	replaceNewLineWithBr: (str) ->
		str.replace(/(?:\r\n|\r|\n)/g, '<br />')

	screenMessage: ->
		ap.api 'get screens', {}, (rsp) ->
			if rsp.message?
				if rsp.message.activated == "yes"
					if !$('#home-screen-overlay').length
						wall.stopAutoScroll()
						$('body').append('<div id="home-screen-overlay" style="display: none"><h1>' + rsp.message.title + '</h1><p>' + wall.replaceNewLineWithBr rsp.message.message + '</p></div>')
						$("#home-screen-overlay").css("width", $(window).width())
									 .css('height', $(window).height())
									 .fadeIn("slow")
					else if (wall.message.message != rsp.message.message) or (wall.message.title != rsp.message.title)
						$("#home-screen-overlay").html('<h1>' + rsp.message.title + '</h1><p>' + wall.replaceNewLineWithBr rsp.message.message + '</p>')
				else if (rsp.message.activated == "no") and $('#home-screen-overlay').length
					$("#home-screen-overlay").fadeOut "slow", ->
						$('#home-screen-overlay').remove()
						wall.autoScroll()

				wall.message = rsp.message

			setTimeout =>
				wall.screenMessage()
			, 1000000

	autoScroll: ->
		# return false
		rightNow = new Date().getTime()

		unless @autoScrollTimerStart?
			@autoScrollTimerStart = rightNow

		diff = rightNow - @autoScrollTimerStart
		pixels = diff / @autoScrollDelay

		if diff > @autoScrollDelay
			newDelay = 0
		else
			newDelay = @autoScrollDelay - diff

		@autoScrollTimerStart = rightNow
		# # window.scrollBy((-1*pixels),0)
		# $('#waterfall').animate {left: "-="+20}, 1000, =>
		# 	setTimeout ->
		# 		@autoScroll()
		# 	, 100
		left = parseInt(wall.$el.css('left')) - 15
		wall.$el.css('left', _.x(left))
		@loadMoreContentIfWeScrolledLeftEnough()
		@autoScrollTimo = setTimeout =>
			@autoScroll()
		, 1000

		# @autoScrollTimo = setTimeout =>
		# 	@autoScroll()
		# , 1000

	stopAutoScroll: ->
		if @autoScrollTimo?
			clearTimeout(@autoScrollTimo)
		@autoScrollTimo = null
		@autoScrollTimerStart = null

	initSafari: ->
		isSafari = !!navigator.userAgent.match(/Version\/[\d\.]+.*Safari/)
		if isSafari && !$('#safari-wall-styles').length
			$('body').append '
				<style type="text/css" id="safari-wall-styles">
					.tpl-1 .wall-content-type-speaker_quote.block-7,
					.tpl-0 .block-1,
					.tpl-3 .block-8,
					.tpl-2 .wall-content-type-featured_tweet.block-2 {
						display: block !important;
					}
				</style>
			'


	# Extending the Google Maps API
	extendMaps: ->
		_.whenReady 'googlemaps', =>
			google.maps.Map.prototype.shiftY= (offsetY) ->
			    map = this
			    ov = new google.maps.OverlayView()
			    ov.onAdd = ->
			        proj = this.getProjection()
			        aPoint = proj.fromLatLngToContainerPixel(map.getCenter())
			        aPoint.y = aPoint.y+offsetY
			        map.setCenter(proj.fromContainerPixelToLatLng(aPoint))
			    ov.draw = (->)
			    ov.setMap(this)
			_.nowReady 'googlemapsextended'

	# Get content from API
	# Note: currently gets all the content we have but
	# this may need to change in the future
	loadContent: (cb) ->
		if not wall.content
			_.whenReady 'assets', =>
				ap.api 'get content', {}, (rsp) =>
					wall.content = rsp.content
					for content in wall.content
						if not wall.contByType[content.type]?
							wall.contByType[content.type] = []
						wall.contByType[content.type].push content

					answers = {}
					wall.ansByQ = {}
					for answer in rsp.answers
						unless answers[answer.user_id]?
							answers[answer.user_id] = {}
						unless wall.ansByQ[answer.question_id]?
							wall.ansByQ[answer.question_id] = []
							answers[answer.user_id] = {}
						wall.ansByQ[answer.question_id].push answer

					wall.attendees = rsp.attendees
					wall.atnById = {}
					for atn in rsp.attendees
						atn.distance = Math.ceil(atn.distance)
						wall.atnById[atn.user_id] = atn

					wall.contByType['speaker'] = []
					for type,list of ap.speakers
						for speaker in list
							speaker.data = JSON.stringify(speaker)
							speaker.content_id = speaker.speaker_id
							wall.contByType['speaker'].push speaker
					wall.contByType['speaker'] = _.shuffle(wall.contByType['speaker'])

					wall.contByType['speaker_quote'] = []
					for type,list of ap.speakers
						for speaker in list
							inx = 0
							for quote in speaker.quotes
								speaker.quote = quote
								speaker.data = JSON.stringify(speaker)
								speaker.content_id = speaker.speaker_id+inx
								inx += 1
								wall.contByType['speaker_quote'].push speaker

					cb()
		else
			cb()

	# Load templates from the DOM and remove them
	# Note: Maybe these should be in separae tpl files, but
	# I like having everything relevant in home.jade
	loadTpls: ->
			self = this
			$('.tpl', '#wall-tpls').each ->
				wall.tpls.push $(this).html()
			$('#wall-tpls').remove()

			$('.tpl', '#block-tpls').each ->
				$t = $(this)
				type = $t.data('type')
				tpl =
					html: $t.html()
					type: type
				unless wall.block_tpls[type]
					wall.block_tpls[type] = []
				wall.block_tpls[type].push tpl
			$('#block-tpls').remove()

	# Generate panels until we have enough
	generateWallPanels: ->
		while $('.wall-section', wall.$q).length < 10
			@generateWallPanel()
		@displayPanels()

	# Select a random template, fill content
	# and add the panel
	generateWallPanel: ->
		$tpl = @randTpl()
		$tpl = @fillContent($tpl)
		wall.$q.append($tpl)

	displayPanels: ->
		if @screenMode
			left = $('#waterfall').css('left')
			space = wall.drawnHeight - ($(window).width() + Math.abs(parseInt(left)))
			shouldLoadMore = space < $(window).width()
		else
			space = $('#waterfall').height() - wall.drawnHeight
			shouldLoadMore = space > 100
		if shouldLoadMore
			queue = $('.wall-section', wall.$q)
			if queue? and queue.length
				_.nowReady('firstpanel')
				_next = $(queue[0])
				next = _next.clone()
				if next.hasClass("tpl-2")
					randTop = Math.random() * (100 - 30) + 30;
					next.css('top', _.x(randTop))
				_next.remove()
				wall.$el.append next
				if @screenMode

					# This is technically width in horizontal mode
					wall.drawnHeight += next.width()
					wall.$el.css('width', _.x(wall.drawnHeight + 100))
				else
					wall.drawnHeight += next.height()
				@postProcess next
			queue = $('.wall-section', wall.$q)
			if queue.length < 5
				@generateWallPanels()
			@displayPanels()

	# Get a random template
	randTpl: ->
		tpl = $.random(0, wall.tpls.length-1)
		return wall.tpls[tpl]

	fillContent: ($tpl) ->
		self = this
		$tpl = $($tpl)
		count = 0
		$('.wall-content', $tpl).each ->
			$t = $(this)
			id = +(new Date())+'_'+count
			$t.attr('id', id)
			count += 1
			type = $t.data('type')
			opts =
				maxchars: $t.data('maxchars')
				max: $t.data('max')
				question: $t.data('question')
				orientation: $t.data('orientation')
				atn_form: $t.data('atn_form')

			# Some randomized properties
			if opts.orientation
				$t.addClass 'orientation-'+opts.orientation
			if type is 'icon'
				icon = _.shuffle(['zig-zag', 'dots', 'squiggle'])[0]
				$t.addClass('icon-'+icon)
			content = self.getContent(type, opts)
			blocks = _.shuffle(wall.block_tpls[type])
			block_html = _.template(blocks[0].html, content)
			if type
				$t.addClass('wall-content-type-'+type)
			$t.addClass('block-'+count)
			$t.addClass('block')
			$t.html block_html

			if type is 'flickr_stream'
				$t.attr('href', '#')
			if type is 'attendee'
				$t.attr('href', '/~'+content.user_name).attr('target', '_blank')
			if type is 'attendee_map'
				$t.attr('href', '/~'+content.user_name).attr('target', '_blank')
			if type is 'attendee_answer'
				$t.attr('href', '/~'+content.user_name).attr('target', '_blank')
			if type is 'race'
				$t.attr('href', '/race').attr('target', '_blank')
			if type is 'speaker'
				$t.attr('href', '/speakers/'+_.slugify(content.display_name)).attr('target', '_blank')
			if type is 'speaker_quote'
				$t.attr('href', '/speakers/'+_.slugify(content.display_name)).attr('target', '_blank')


			# Post HTML Added
			if type is 'icon'
				ic_num = _.shuffle([1,2,3,4,5,6])[0]
				the_icon = $('<div/>')
				.attr('class', 'the_icon')
				.attr('style', 'background-position: -'+ic_num*100+'px 0 !important')
				$t.append(the_icon)
			if opts.atn_form is 'envelope'
				bg = _.shuffle([1,2,3,4,5,6])[0]
				$('.pattern-bg', $t).attr('style', 'background-position: -'+(bg*175)+'px 0 !important')
			if opts.atn_form is 'box'
				bg = _.shuffle([1,2,3,4,5,6])[0]
				$('.pattern-bg', $t).attr('style', 'background-position: -'+(bg*192)+'px 0 !important')
			wall.block_data[id] =
				type: type
				content: content
				opts: opts
		return $tpl

	# Handle anything that needs to happen to a block
	# after it's loaded into the DOM
	postProcess: ($tpl) ->
		$tpl.find().css("cursor", "none")
		_.whenReady 'googlemaps', =>
			_.whenReady 'googlemapsextended', =>
				$('.attendee_map', $tpl).each ->
					$t = $(this)
					block = $t.closest('.block')
					obj = wall.block_data[block.attr('id')]
					content = obj.content
					map = $t.attr('id', 'map-'+(+(new Date())))
					profile_map_el = document.getElementById(map.attr('id'))
					mapOptions =
						center: new google.maps.LatLng(content.lat, content.lon)
						zoom: 8
						scrollwheel: false
						disableDefaultUI: true
						draggable: false
					profile_map = new google.maps.Map(profile_map_el, mapOptions)
					line = [
						new google.maps.LatLng(content.lat, content.lon),
						new google.maps.LatLng('45.523452', '-122.676207'),
					]
					path = new google.maps.Polyline
						path: line,
						geodesic: true,
						strokeColor: '#E27F1C',
						strokeOpacity: 1.0,
						strokeWeight: 3
					path.setMap profile_map
					bounds = new google.maps.LatLngBounds()
					bounds.extend line[0]
					bounds.extend line[1]
					profile_map.fitBounds(bounds)
					shift = $('.attendee_map_text', $t.closest('.block')).height() * -1
					profile_map.shiftY(shift)

	renderArmyMap: ->
		army_map_el = document.getElementById('army-map')
		mapOptions =
			center: new google.maps.LatLng(30.4419, -60.1419)
			zoom: 3
			scrollwheel: false
			disableDefaultUI: true
		army_map = new google.maps.Map(army_map_el, mapOptions)

		llid = (lat, lon) ->
			return lat.replace('-', 'nn').replace('.', 'o')+lon.replace('-', 'nn').replace('.', 'o')

		used = {}
		getValidLatLon = (user) ->
			uniq = false
			lat = ''+user.get('lat')
			lon = ''+user.get('lon')
			while not uniq
				ll = llid(lat, lon)
				if not used[ll]?
					used[ll] = true
					uniq = true
				else
					lat = lat.substr(0, lat.length-1)
					lon = lon.substr(0, lon.length-1)
					lat += Math.floor(Math.random()*11)
					lon += Math.floor(Math.random()*11)
			return new google.maps.LatLng(lat, lon)

		ap.Users.each (user) ->
			if user.get('lat')? and user.get('lon')? and user.get('pic')?.length
				marker = new google.maps.Marker
					position: getValidLatLon(user)
					map: army_map
					title:'View Profile'
					icon: '/images/markers/'+user.get('user_name')+'_m.png',
					width:10
		@armyRendered = true

	pruneUsed: (type)->
		tmp = []


		wall.used_content[type] = tmp

	showVideo: (e) ->
		if not ap.isMobile
			e.preventDefault()
			setTimeout ->
				$('#the-video').append('<iframe class="modal-remove" src="//player.vimeo.com/video/'+VIMEO_ID+'?title=0&amp;byline=0&amp;portrait=0&amp;autoplay=1" width="780" height="496" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>')
			, 2
			ap.Modals.open('video')
		else
			location.href = 'http://player.vimeo.com/video/'+VIMEO_ID+'?title=0&amp;byline=0&amp;portrait=0&amp;autoplay=1'

	showArmy: (e) ->
		e.preventDefault()
		ap.Modals.open('army')
		unless wall.armyRendered?
			wall.renderArmyMap()

	showBiggerPhoto: (e) ->
		e.preventDefault()
		url = $('.flickr-photo', $(this)).data('url')
		img = $('#modal-bigger-photo-img')
		cont = $('.modal-content', $('#modal-bigger-photo'))
		cont.attr('style', '')
		img.attr('src', url).load ->
			ap.Modals.open('bigger-photo')
			cont.css('width', (img.width()+20)+'px')
			cont.css('height', (img.height()+20)+'px')
	getContent: (type, opts) ->
		if type is 'icon'
			icon =
				icon: ''
			return icon

		if type is 'speaker_quote_photo'
			type = 'speaker_quote'

		if type is 'attendee'
			attendees = _.shuffle(wall.attendees)
			return attendees[0]

		if type is 'attendee_map'
			attendees = _.shuffle(wall.attendees)
			for atn in attendees
				pass = true
				if opts.max?
					bits = opts.max.split(':')
					unless +atn[bits[0]] < +bits[1]
						pass = false
				if atn.distance > 300 and pass
					return atn

		if type is 'race'
			content = {}
			html = ''
			if ap.ranks?
				for rank in [0..2]
					user = ap.Users.get(ap.ranks[rank].user_id)
					html += '
						<div class="rank-row">
							<div class="rank-avatar" style="background:url('+user.get('pic')+')"></div>
							<span>'+user.get('first_name')+' '+user.get('last_name')+'</span>
						</div>'
			else
				html = 'Ranks are loading, hang tight!'
			content.html = html
			return content

		if type is 'attendee_answer'
			answers = _.shuffle(wall.ansByQ[opts.question])
			for answer in answers
				bits = opts.maxchars.split(':')
				ans = answer.answer
				if ans.length < +bits[1]
					if wall.atnById[answer.user_id]?
						atn = wall.atnById[answer.user_id]
						atn.answer = ans
						atn.pre_name  = ''
						atn.post_name  = ''
						if opts.question is 1
							atn.answer = '<span class="answer_start">is coming to WDS because...</span> '+ans
						if opts.question is 3
							atn.post_name = "'s super-power is..."
						return atn

		fetchFrom = wall.contByType[type] # Types left after this point = flickr_stream, featured_tweets, speaker_quotes
		for content in fetchFrom
			unless wall.used_content[type]
				wall.used_content[type] = []
			if (wall.used_content[type].indexOf(content.content_id) is -1)
				data = JSON.parse(content.data)

				pass = true

				if opts.maxchars?
					bits = opts.maxchars.split(':')
					unless data[bits[0]].length < +bits[1]
						pass = false

				if opts.orientation?
					unless data.orientation is opts.orientation
						pass = false

				if type is 'flickr_stream' and not data.the_img_med?
					pass = false

				if pass
					wall.used_content[type].push content.content_id
					return data

		#If we made it here, we need to reset the used content and try again
		@pruneUsed type
		return @getContent type, opts
