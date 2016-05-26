ap.Views.academy = XView.extend
  initialize: ->
    ap.api 'get event', {slug: @options.slug}, (rsp) =>
      @event = rsp.event
      @event.what_no_the = @event.what.replace('The', '')
      ap.activeAcademy = @event
      @event.descr = markdown.toHTML(@event.descr)
      @event.who = markdown.toHTML(@event.who)
      @options.out = _.template @options.out, @event
      @options.sidebar = 'academy'
      @options.sidebar_filler = @event
      @initRender()

  sidebarRendered: ->
    ev = @event
    status = 'normal'
    ac = ap.activeAcademy
    if ac.num_free >= ac.free_max
      free_maxed = true
    if ap.me? and ap.me and parseInt(ap.me.get('attending'+ap.yr)) is 1
      if ap.me.get('academy') > 0
          status = 'normal'
      else
        if free_maxed
          status = 'free-maxed'
        else
          status = 'claim'
    if ev.num_rsvps? and ev.num_rsvps > ev.max
      status = 'maxed'
    $('.rsvp-button', '#sidebar').attr('data-status', status)
    $('body').on 'click', '.academy-purchase-start', (e) ->
        $t = $(e.currentTarget)
        e.preventDefault()
        unless $t.hasClass('attending')
          ap.Modals.open('academy-purchase')

  rendered: ->
    @renderMap()
    _.whenReady 'users', =>
      @renderHosts()
      @renderAttendees()
      _.whenReady 'assets', =>
        $(@el).scan({rescan: true})

  renderMap: ->
    if @event.place?.length
      $('body').addClass('has-venue')
      _.whenReady 'googlemaps', =>
        ev = @event
        profile_map_el = document.getElementById('meetup-profile-map')
        latlon = new google.maps.LatLng(ev.lat, ev.lon)
        mapOptions =
          center: latlon
          zoom: 16
          scrollwheel: false
          disableDefaultUI: true
        profile_map = new google.maps.Map(profile_map_el, mapOptions)
        marker = new google.maps.Marker
        position: latlon
        map: profile_map
        title: 'Your Meetup\'s Venue'
    else
      $('body').addClass('no-venue')

  renderHosts: ->
    html = '<div class="meetup-hosted-by">Hosted by</div>'
    bhtml = ''
    bios = JSON.parse(@event.bios)
    tk bios
    for host in @event.hosts
      host = ap.Users.get(host.user_id)
      bio = bios[host.get('user_id')]
      if host
        html += '
          <div class="meetup-host-shell">
            <div class="meetup-host-avatar" style="background:url('+host.get('pic')+')"></div>
            <div class="meetup-host-name">'+host.get('first_name')+' '+host.get('last_name')+'</div>
          </div>
        '
        bhtml += '
          <div class="meetup-bio-shell">
            <div class="meetup-host-avatar" style="background:url('+host.get('pic')+')"></div>
            <div class="meetup-bio-content">
              <div class="meetup-bio-name">'+host.get('first_name')+' '+host.get('last_name')+'</div>'+bio+'
            </div>
          </div>
        '
    $('.meetup-hosts', $(@el)).html(html)
    $('.meetup-bios', $(@el)).html(bhtml)

  renderAttendees: ->
    clearTimeout(@atnTimo)
    ap.api 'get event/attendees', {event_id: @event.event_id}, (rsp) =>
      if rsp.attendees?.length > 0
        str = rsp.attendees.length+' WDSers Are Attending'
        if rsp.attendees.length is 1
          str = rsp.attendees.length+' WDSer Is Attending'
        html = '
        <div class="line-canvas"></div>
        <h3>'+str+'</h3>
        <div id="meetup-attendees-shell">
        '
        noPic = []
        for atn in rsp.attendees
          atn = ap.Users.get(atn)
          if atn? and atn.get('pic') isnt '/images/default-avatar.png'
            html += '
            <div class="meetup-attendee">
            <a href="/~'+atn.get('user_name')+'">
              <div class="meetup-attendee-avatar" style="background:url('+atn.get('pic')+')"></div>
              <div class="meetup-attendee-name">'+atn.get('first_name')+'<br>'+atn.get('last_name')+'</div>
            </a>
            </div>'
          else if atn?
            noPic.push atn
        for atn in noPic
          html += '
          <div class="meetup-attendee">
          <a href="/~'+atn.get('user_name')+'">
            <div class="meetup-attendee-avatar" style="background:url('+atn.get('pic')+')"></div>
            <div class="meetup-attendee-name">'+atn.get('first_name')+'<br>'+atn.get('last_name')+'</div>
          </a>
          </div>'
        html += '</div>'

        toggle_class = 'meetup-attendees-closed'
        link_text = 'Show All Attendees'
        if $('.meetup-attendees-opened').length
          toggle_class = 'meetup-attendees-opened'
          link_text = 'Show Less Attendees'
        $('#meetup-attendees').html(html)
        $m = $('#meetup-attendees-shell')
        if $m.height() > '180'
          $m.css('max-height', '154px')
          .append('<a href="#" class="meetup-attendees-toggle">'+link_text+'</a>')
          .addClass(toggle_class)
    @atnTimo = setTimeout =>
      @renderAttendees()
    , 30000

  toggle_attendees: (e) ->
    e.preventDefault()
    $t = $(e.currentTarget)
    $m = $('#meetup-attendees-shell', $(@el))
    $a = $('.meetup-attendees-toggle', $(@el))
    if $m.hasClass('meetup-attendees-closed')
      $m.addClass('meetup-attendees-opened')
      .removeClass('meetup-attendees-closed')
      $a
      .html('Show Less Attendees')
    else
      $m.removeClass('meetup-attendees-opened')
      .addClass('meetup-attendees-closed')
      $a
      .html('Show All Attendees')

  whenFinished: ->
    ap.activeAcademy = false
    $('body').removeClass('has-venue')
    $('body').removeClass('no-venue')
    clearTimeout(@atnTimo)