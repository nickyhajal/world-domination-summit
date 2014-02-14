ap.Views.home = XView.extend
	initialize: ->
		@initRender()
	rendered: ->
		wall.init()

window.wall =
	###
	grid: []
	blocklist: []
	_blocklist: []
	blockcount: 0
	blocks: {}
	###

	# Variables
	used_content: {}
	block_tpls: {}
	tpls: []
	contByType: {}
	block_data: {}

	# Methods
	init: ->
		$.scrollTo(0)
		wall.$el = $('#waterfall')
		wall.$q = $('#wall-queue')
		$(window).on('scroll', wall.scroll)
		@loadContent()
		@loadTpls()
	#	wall.registerInitialBlocks()
	#	wall.fillNextBlock()
	#	wall.fillWall()

	scroll: ->
		$wall = $('#waterfall')
		if (window.scrollY / window.scrollMaxY) * 10 > 8
			$wall.css('height', ($wall.height()+800)+'px')
			wall.displayPanels()

	loadContent: ->
		ap.api 'get content', {}, (rsp) =>
			wall.content = _.shuffle rsp.content
			for content in wall.content
				if not wall.contByType[content.type]?
					wall.contByType[content.type] = []
				wall.contByType[content.type].push content

			answers = {}
			wall.ansByQ = {}
			for answer in rsp.answers
				unless answers[answer.userid]?
					answers[answer.userid] = {}
				unless wall.ansByQ[answer.questionid]?
					wall.ansByQ[answer.questionid] = []
					answers[answer.userid] = {}
				wall.ansByQ[answer.questionid].push answer

			wall.attendees = rsp.attendees
			wall.atnById = {}
			for atn in rsp.attendees
				atn.distance = Math.ceil(atn.distance)
				wall.atnById[atn.attendeeid] = atn
			@fillContent($('.wall-section'))
			@generateWallPanels()

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

	generateWallPanels: ->
		while $('.wall-section', wall.$q).length < 10
			@generateWallPanel()
		@displayPanels()

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
				question: $t.data('question')
				orientation: $t.data('orientation')
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
			wall.block_data[id] =
				type: type
				content: content
				opts: opts
		return $tpl

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

	pruneUsed: (type)->
		tk 'prune: '+type
		tmp = []
		###
		count = 0
		for cont in wall.used_content[type]
			tmp.push cont
			if (count > 5)
				break
			count += 1
			###
		wall.used_content[type] = tmp

	getContent: (type, opts) ->
		if type is 'icon'
			icon =  
				icon: ''
			return icon

		if type is 'speaker' or type is 'speaker_quote_photo'
			type = 'speaker_quote'

		if type is 'attendee'
			attendees = _.shuffle(wall.attendees)
			return attendees[0]

		if type is 'attendee_map'
			attendees = _.shuffle(wall.attendees)
			for atn in attendees
				if atn.distance > 300
					return atn

		if type is 'attendee_answer'
			answers = _.shuffle(wall.ansByQ[opts.question])
			for answer in answers
				bits = opts.maxchars.split(':')
				ans = answer.answer
				if ans.length < +bits[1]
					if wall.atnById[answer.userid]?
						atn = wall.atnById[answer.userid]
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
			if (wall.used_content[type].indexOf(content.contentid) is -1)
				data = JSON.parse(content.data)

				pass = true

				if opts.maxchars?
					bits = opts.maxchars.split(':')
					unless data[bits[0]].length < +bits[1]
						pass = false

				if opts.orientation?
					unless data.orientation is opts.orientation
						pass = false

				if pass
					wall.used_content[type].push content.contentid
					return data

		#If we made it here, we need to reset the used content and try again
		@pruneUsed type
		return @getContent type, opts



























###
	registerInitialBlocks: ->
		self = this
		$('.waterfall-content').each ->
			$t = $(this)
			id = $t.attr('id')
			top = parseInt $t.css('top')
			left = parseInt $t.css('left')
			w = $t.width()
			h = $t.height()
			self.registerBlock 
				id: id, 
				top: top, 
				left: left, 
				width: w, 
				height: h
	fillWall: ->
		$wall = $('#waterfall')
		count = 0
		while( ($wall.height() + $wall.offset().top) - wall.blocklist[0].end.top  > 100)
			@fillNextBlock()
			count += 1
			if (count > 8000)
				tk 'BREEEEEEEEEEEEEEEEEEEAAAAAAAAAAAAAAAAAAAKKKKKKKKKKKKKKKKKKK'
				break
	registerBlock: (block) ->
		startTop = block.top
		endTop = block.top + block.height 
		if block.pad_bottom?
			endTop += block.pad_bottom
		startLeft = block.left
		endLeft = block.left + block.width
		if block.pad_right?
			endLeft += block.pad_right
		for t in [startTop..endTop]
			for l in [startLeft..endLeft]
				unless wall.grid[t]?
					wall.grid[t] = []
				wall.grid[t][l] = block.id
		wall._blocklist.push
			id: block.id
			start:
				top: block.top
				left: block.left
			end:
				top: endTop
				left: endLeft
		wall.blocklist = wall._blocklist.slice(0).reverse()
		wall.blocks[block.id] = block

	# Core function that requests and paints a new block
	fillNextBlock: ->
		next = @findNextBlock(wall.blocklist[0].start.top)
		block = @requestBlock(next)
		#block.top = @getNextTop(block)
		block.id = 'b-'+@blockcount
		stats = '
		r: ' + block.ratio + '<br>
		pr: ' + block.pad_right+ '<br>
		pb: ' + block.pad_bottom+ '<br>
		w: ' + block.width+ '<br>
		h: ' + block.height+ '<br>
		t: ' + block.top+ '<br>
		l: ' + block.left+ '<br>
		'
		#stats = ''
		$el = $('<div/>')
			.attr('id', block.id)
			.addClass('waterfall-content')
			.css
				'top': block.top+'px'
				'left': block.left+'px'
				'width': block.width+'px'
				'height': block.height+'px'
				'background': block.bg
			.html stats
		if block.spacer
			$el
				.addClass('wall-space')
				.html ''
		$('#waterfall').append $el
		@registerBlock block
		@blockcount += 1

	# Core function that begins the process of finding the next
	# appropriate spot and a block to fit it
	findNextBlock: (top)->
		next = 
			pad_right: 0
			pad_bottom: 0
			spacer: false
		coords = @findFromTop (top)
		room = 990 - +coords.left

		# If there's no room for another block, we need to look down more
		if room > 18

			# If we're at the edge, just fill it up
			next.width = $.random(11, 22) * 15
			next = @generatePadding next
			if (990 - (+coords.left + next.width + next.pad_right)) < 165
				next.width = room - next.pad_right

			next.left = coords.left
			next.top = coords.top
			next = @checkNeighbors next
			return next
		else
			return @findNextBlock(top+1)

	generateHeight: (block) ->
		if not block.spacer
			if block.width > 395
				$.randrun ->
					block.height = (3/4) * block.width
					block.ratio = '3:4'
			else if block.width > 220
				$.randrun ->
					block.height = (4/3) * block.width
					block.ratio = '4:3'
				, ->
					block.height = (3/4) * block.width
					block.ratio = '3:4'
				, ->
					block.height = (16/10) * block.width
					block.ratio = '16:9'
				, ->
					block.height = (10/16) * block.width
					block.ratio = '9:16'
			else
				block.height = block.width
				block.ratio = '1:1'
		return block
	requestBlock: (block)->
		block = @generateHeight(block)
		block.bg = '#'+Math.floor(Math.random()*16777215).toString(16)
		if block.bg.length is 6
			block.bg += '1'
		return block

	generatePadding: (block) ->
		if not block.spacer
			$.randrun [12, 12, 5, 71], ->
				block.pad_right = $.random(1, 6) * 15
				block.pad_bottom = 0
			, ->
				block.pad_right = 0
				block.pad_bottom = $.random(1, 6) * 15
			, ->
				block.pad_right = $.random(1, 6) * 15
				block.pad_bottom = $.random(1, 6) * 15
			, ->
				block.pad_right = 0
				block.pad_bottom = 0
		return block

	checkNeighbors: (block) ->
		top = block.top + 1
		startLeft = block.left + 1
		endLeft = block.left + block.width + block.pad_right
		neighborStart = false
		overlapStart = false

		# First we check to see if we're overlapping
		# another block
		for left in [startLeft..endLeft]
			if wall.grid[top]?[left]?
				overlapStart = left
				break

		# If so, shorten up our box
		if overlapStart
			block.width = overlapStart - block.left
			if block.width < 165 
				block.height = 10
				bot = top + block.height
				rightH = leftH = false
				lNeighbor = wall.blocks[wall.grid[bot][startLeft-5]]
				if lNeighbor?
					leftH = lNeighbor.top + lNeighbor.height + lNeighbor.pad_bottom
				rNeighbor = wall.blocks[wall.grid[bot][endLeft+5]]
				if rNeighbor?
					rightH = rNeighbor.top + rNeighbor.height + rNeighbor.pad_bottom

				block.spacer = true
				if (not rightH) or (leftH && leftH < rightH)
					block.height = leftH - top + 1
				else
					block.height = rightH - top + 1

		# If not, check if there's a gap close enough to the
		# next neighbor worth filling
		else
			for left in [endLeft..990]
				if wall.grid[top]?[left]?
					neighborStart = left
					break

		# If so, extend to the neighbor
		if neighborStart and (neighborStart - endLeft < 100)
			block.width = neighborStart - block.left

		# Sometimes we will knowingly overlap a neighbor
		# just to be silly
		if @blockcount > 6 and not block.spacer
			$.randrun ->
				block.left -= 15
				block.width += 30
			, ->
				block.width += 15
			, ->
				block.height += 15
			, ->
				block.top -= 15
				block.height += 30

		return block

	findFromTop: (top) ->
		while 1
			for left in [0..990]
				block =
					top: top + 1
					left: left
					width: 20
					height: 20
				if (@blockFits block)
					return {top: top,left:left-1}
			top += 1

	blockFits: (block) ->
		startTop = block.top
		endTop = block.top + block.height
		startLeft = block.left
		endLeft = block.left + block.width
		for top in [startTop..endTop]
			for left in [startLeft..endLeft]
				if wall.grid[top]?[left]?
					return false
		return true



	## DEPRECATED ##
	getNextTop: (block) ->
		top = block.top
		left = block.left + 1
		endLeft = block.left + block.width
		open = true

		while wall.grid[top]?[left]?
			top += 1

		for l in [left..endLeft]
			if wall.grid[top]?[l]?
				block.top = top
				block.left = l
				open = false
				return @getNextTop(block)
		if open
			return top - 1
###

