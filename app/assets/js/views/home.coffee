ap.Views.home = XView.extend
	initialize: ->
		@initRender()
	rendered: ->
		wall.init()

window.wall =

	# Variables
	used_content: {}
	block_tpls: {}
	tpls: []
	contByType: {}
	block_data: {}

	# Methods
	init: ->
		@extendMaps()
		$.scrollTo(0)
		wall.$el = $('#waterfall')
		wall.$q = $('#wall-queue')
		$(window).on('scroll', wall.scroll)
		@loadContent =>
			@fillContent($('.wall-section'))
			@generateWallPanels()
		@loadTpls()
		$('body')
			.on('click', '.wall-content-type-flickr_stream', wall.showBiggerPhoto)
			.on('click', '#video', wall.showVideo)
			.on('click', '#reg-army', wall.showArmy)

	# Extending the Google Maps API
	extendMaps: ->
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

	scroll: ->
		$wall = $('#waterfall')

		# Determine if we're ready to add more panels
		if (window.scrollY / (document.documentElement.scrollHeight - document.documentElement.clientHeight)) * 10 > 8
			$wall.css('height', ($wall.height()+800)+'px')
			wall.displayPanels()

	# Get content from API
	# Note: currently gets all the content we have but
	# this may need to change in the future
	loadContent: (cb) ->
		if not wall.content
			ap.api 'get content', {}, (rsp) =>
				wall.content = _.shuffle rsp.content
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
						speaker.content_id = speaker.speakerid
						wall.contByType['speaker'].push speaker

				wall.contByType['speaker_quote'] = []
				for type,list of ap.speakers
					for speaker in list
						inx = 0
						for quote in speaker.quotes
							speaker.quote = quote
							speaker.data = JSON.stringify(speaker)
							speaker.content_id = speaker.speakerid+inx
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
		last = $('#waterfall .wall-section').last()
		space = $('#waterfall').height() - (last.offset().top + last.height())
		if space > 100
			queue = $('.wall-section', wall.$q)
			if queue? and queue.length
				_next = $(queue[0])
				next = _next.clone()
				_next.remove()
				wall.$el.append next
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
			if type is 'speaker'
				$t.attr('href', '/speaker/'+_.slugify(content.display_name)).attr('target', '_blank')
			if type is 'speaker_quote'
				$t.attr('href', '/speaker/'+_.slugify(content.display_name)).attr('target', '_blank')


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
				ll = llid(lat, lon);
				if not used[ll]?
					used[ll] = true
					uniq = true;
				else
					lat = lat.substr(0, lat.length-1);
					lon = lon.substr(0, lon.length-1);
					lat += Math.floor(Math.random()*11);
					lon += Math.floor(Math.random()*11);
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
			ap.Modals.open('video')
		else
			location.href = 'http://pdl.vimeocdn.com/04742/403/190797832.mp4?token2=1398959498_d8c9826c574ed46a8fdc24b7c55d1906&aksessionid=20af3f7a27a06ddb'

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

		fetchFrom = wall.contByType[type]
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