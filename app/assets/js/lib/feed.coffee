(($)->
	$.fn.feed = (fnc = false, opts = {})->

		$t = $(this)
		$d = $t.closest('.dispatch')
		$t.empty()
		$el = $(this)
		slf = this
		defs = 
			render: 'replace'
			update: 5000
			params:
				feed_type: 'personal' #change to opposite
				page: 1

		loadingComments = []

		updTimo = 0

		if fnc and typeof fnc isnt 'string'
			opts = fnc
			fnc = false

		opts = _.defaults opts, defs
		if $d.data('channel_id')?
			opts.params.channel_id = $d.data('channel_id')
		if $d.data('channel_type')?
			opts.params.channel_type = $d.data('channel_type')

		@renderFeed = (contents, render = 'replace') ->
			html = ''
			$inner = $('.dispatch-container', $el)
			if !$inner.length
				$el.append('<div class="dispatch-container"/>')
				$inner = $('.dispatch-container', $el)
			if contents.length
				for content in contents
					html += @renderContent content
			else if not $('.dispatch-content-shell', $el).length
				render = 'replace'
				html += '<div class="dispatch-empty">No posts yet! Why don\'t you get things started?</div>'
			if render is 'replace'
				$inner.html html
			else if render is 'append'
				$inner.append html
			else if render is 'prepend'
				$inner.prepend html
			setTimeout =>
				@process()
			, 25
			return html

		@commentsStr = (num_comments) ->
			if num_comments > 1
				comments = num_comments+' comments'
			else if num_comments
				comments = num_comments+' comment'
			else
				comments = 'Add a Comment'
			return comments
		@likeStr = (feed_id, num_likes) ->
			str = ''
			if num_likes > 0
				str += '<div class="dispatch-content-like-status">'
			if num_likes > 1
				str += num_likes + ' Likes</div>'
			else if num_likes
				str += num_likes + ' Like</div>'
			if ap.me
				if ap.me.get('feed_likes')? && (ap.me.get('feed_likes').indexOf(feed_id) > -1)
					str += '<a href="#" class="dispatch-content-liked">Liked!</a>'
				else
					str += '<a href="#" class="dispatch-content-like">Like</a>'
			return str

		@renderContent = (content) ->
			author = ap.Users.get(content.user_id)
			html = ''
			if author?
				comments = @commentsStr +content.num_comments
				like = @likeStr(content.feed_id, +content.num_likes)
				channel_name = content.channel_type
				channel_url = '#'
				if channel_name is 'interest'
					channel_name = ap.Interests.get(content.channel_id).get('interest').toLowerCase()
					channel_url = '/community/'+_.slugify(channel_name)
				else if channel_name is 'global'
					channel_url = '/hub'
				html = '
					<div class="dispatch-content-shell dispatch-content-unprocessed" data-content_id="'+content.feed_id+'">
						<div class="dispatch-content-userpic" style="background:url('+author.get('pic').replace('_normal', '')+')"></div>
						<div class="dispatch-content-section">
							<a href="/~'+author.get('user_name')+'" class="dispatch-content-author">
								'+author.get('first_name')+' '+author.get('last_name')+'
							</a>
							<div class="dispatch-content-message">'+Autolinker.link(content.content.replace(/\n/g, '<br>').replace(/<br>\s<br>/g, '<br>'))+'</div>
							<div class="dispatch-content-channel-shell">
								<a href="'+channel_url+'" class="dispatch-content-channel">/'+channel_name+'</a>
							</div>
							<div class="dispatch-content-comments-shell dispatch-content-comments-closed">
								<div class="dispatch-content-like-shell">' + like + '</div>
								<a href="#" class="dispatch-content-comment-status">'+comments+'</a>
									<div class="dispatch-content-comments-inner">
										<div class="dispatch-content-comments"></div>
											<form id="dispatch-content-comment-form'+content.feed_id+'" class="dispatch-content-comment-form" action="#" method="post">
											'
				if ap.me
					html += '
							<div class="dispatch-content-userpic" style="background:url('+ap.me.get('pic')+')"></div>
							<textarea placeholder="Leave a comment" name="comment" class="dispatch-content-comment-inp"></textarea>
							<input type="submit" class="dispatch-comment-submit" value="Share Comment"/>
					'
				else
					html+= '
						<a href="/login" class="button login-to-comment">Login to Comment</a>
					'
				html += '
								</form>
								</div>
							</div>
						</div>
						<div class="clear-left"></div>
					</div>
				'
			return html

		@process = ->
			$('.dispatch-content-unprocessed').each ->
				$t = $(this)
				$c = $('.dispatch-content-message', $t)
				$c.css('max-height', '10000px')
				height = $c.height()
				$c.css('max-height', '80px')
				if height > 66
					$('<div/>').attr('class', 'dispatch-content-seemore').html('Read More').insertAfter($c)
				$t.removeClass('dispatch-content-unprocessed')
				$('textarea', $t).autosize()

				if slf.isSingle
					$('.dispatch-content-comment-status').mouseover().click()
		@toggleMore = ->
			$t = $(this)
			$s = $t.closest('.dispatch-content-shell')
			$c = $('.dispatch-content-message', $s)
			if $t.hasClass('open')
				$t.removeClass('open').html('Read More')
				$c.css('max-height', '80px')
			else
				$t.addClass('open').html('Show Less')
				$c.css('max-height', '100000px')

		@getContent = (get_opts, extra = {}) ->
			get_defs = 
				render: opts.render
				cb: false
			get_opts = _.defaults get_opts, get_defs
			opts.params.since = $('.dispatch-content-shell', $el).first().data('content_id')
			params = _.defaults extra, opts.params
			ap.api 'get feed', params, (rsp) =>
				@renderFeed(rsp.feed_contents, get_opts.render)
				if get_opts.cb
					get_opts.cb()

		@updateContent = ->
			@getContent
				render: 'prepend'
				cb: ->
					x = 3
					# Animate
			@more_loadComments()

			updTimo = setTimeout =>
				@updateContent()
			, opts.update

		@stop = ->
			clearTimeout(updTimo)
			$('.dispatch-container', this).empty()
			$(this)
				.off('click', '.dispatch-content-seemore', @toggleMore)
				.off('mouseover', '.dispatch-content-comment-status', (e) => @mouseover_loadComments(e, this))
				.off('click', '.dispatch-content-comment-status', @toggleComments)
				.off('submit', '.dispatch-content-comment-form', @submitComment)
			return 'stopped'

		@mouseover_loadComments = (e, self) ->
			$t = $(e.currentTarget)
			$shell = $t.closest('.dispatch-content-shell')
			$c = $('.dispatch-content-comments', $shell)
			content_id = $shell.data('content_id')
			self.loadComments $c, content_id

		@more_loadComments = ->
			self = this
			$('.dispatch-content-comments-open').each ->
				$t = $(this)
				$shell = $t.closest('.dispatch-content-shell')
				$c = $('.dispatch-content-comments', $shell)
				since = $('.comment-shell', $c).last().data('comment_id')
				content_id = $shell.data('content_id')
				if loadingComments.indexOf(content_id) < 0
					loadingComments.push content_id
					self.loadComments $c, content_id, since, 'append'

		@loadComments = (shell, feed_id, since = false, with_content = 'replace') ->
			self = this
			data =
				feed_id: feed_id
			if since
				data.since = since
			ap.api 'get feed/comments', data, (rsp) ->
				if (rsp.comments?.length)
					html = ''
					for comment in rsp.comments
						author = ap.Users.get(comment.user_id	)
						html += '
							<div class="comment-shell" data-comment_id="'+comment.feed_comment_id+'">
								<div class="dispatch-content-userpic" style="background:url('+author.get('pic')+')"></div>
								<a href="/~'+author.get('user_name')+'" class="dispatch-content-author">
									'+author.get('first_name')+' '+author.get('last_name')+'
								</a>
								<div class="comment-message">'+comment.comment.replace(/\n/g, '<br>').replace(/<br>\s<br>/g, '<br>')+'</div>
							</div>
						'
						commentStr = self.commentsStr +rsp.num_comments
						$('.dispatch-content-comment-status', shell.closest('.dispatch-content-shell')).html commentStr
					if with_content == 'replace'
						shell.html html
					else if with_content == 'append'
						shell.append html

				newLoading = []
				for loading in loadingComments
					if loading isnt feed_id
						newLoading.push loading
				loadingComments = newLoading

		@toggleComments = ->
			$tc = $(this)
			$shell = $tc.closest('.dispatch-content-comments-shell')
			if ($shell.hasClass('dispatch-content-comments-closed'))
				$shell.removeClass('dispatch-content-comments-closed')
				$shell.addClass('dispatch-content-comments-open')
			else
				$shell.addClass('dispatch-content-comments-closed')
				$shell.removeClass('dispatch-content-comments-open')
			return false

		@submitComment = ->
			$f = $(this)
			form = $f.formToJson()
			if form.comment.length > 0
				$shell = $f.closest('.dispatch-content-shell')
				content_id = $shell.data('content_id')
				form.feed_id = content_id
				btn = $('.dispatch-comment-submit', $f)
				btn.val('Sharing...')
				ap.api 'post feed/comment', form, (rsp) ->
					if rsp.comment?
						btn.val('Shared!')
						slf.more_loadComments()
					else if rsp.msg?
						btn.val(rsp.msg)
					setTimeout ->
						btn.val('Share Comment')
						$('.dispatch-content-comment-inp', $f).val('').height('46px')
					, 1200
			return false

		@like = ->
			btn = $(this)
			$shell = btn.closest('.dispatch-content-shell')
			content_id = $shell.data('content_id')
			ap.api 'post feed/like', {feed_id: content_id}, (rsp) =>
				if rsp.num_likes
					likes = ap.me.get('feed_likes')
					likes.push(content_id)
					ap.me.set('feed_likes', likes)
					likeStr = slf.likeStr(content_id, rsp.num_likes)
					$('.dispatch-content-like-shell', $shell).html(likeStr)

			return false

		loadingViaScroll = false
		@scroll = =>
			# Determine if we're ready to add more panels
			scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight
			scrollPercent = window.scrollY / scrollHeight * 100
			if scrollPercent > 80 and not loadingViaScroll
				loadingViaScroll = true
				@getContent
					render: 'append'
					cb: ->
						loadingViaScroll = false
				,
					before: $('.dispatch-content-shell', $el).last().data('content_id')

		@initFeedItem = ->
			clearTimeout(updTimo)
			$('.dispatch-controls:visible').remove()
			@isSingle = true

		@init = ->
			@updateContent()
			$(this).data('feed', @)
			$(this)
				.on('click', '.dispatch-content-seemore', @toggleMore)
				.on('mouseover', '.dispatch-content-comment-status', (e) => @mouseover_loadComments(e, this))
				.on('click', '.dispatch-content-comment-status', @toggleComments)
				.on('click', '.dispatch-content-like', @like)
				.on('submit', '.dispatch-content-comment-form', @submitComment)
			if opts.params.channel_type is 'feed_item'
				@initFeedItem()
			$(window).on('scroll', @scroll)

		if not fnc
			@init()


		return $(this)
)(jQuery)