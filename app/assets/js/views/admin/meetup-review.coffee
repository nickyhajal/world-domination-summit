ap.Views.admin_meetup_review = XView.extend
  timo: 0
  events:
    'click .event-button': 'review'
    'click #event-review-results tr': 'row_click'
  initialize: ->
    @initRender()

  rendered: ->
    _.whenReady 'users', =>
      @listing()

  listing: ->
    ap.api 'get admin/events', {active: 0, type: 'meetup'}, (rsp) ->
      html = '<tr class="tbl-head"><th>Host</th><th>Format</th><th>Meetup</th><th>Venue</th><th>Actions</th></tr>'
      for atn in rsp.events
      #   atn = new ap.Event(atn)
        host = ''
        if 1 #ap.Users.get(atn.hosts[0])?
          host = atn.hosts[0]#ap.Users.get(atn.hosts[0])
          host_str = host.first_name+' '+host.last_name
          console.log(host)
          if +host['attending'+ap.yr] != 1
            host_str += ' (Not attending WDS 20'+ap.yr+' - user_id: '+host.user_id+')'
          av = 'http://avatar.wds.fm/'+host.user_id+'?width=64'
        place = if atn.place.length then atn.place else 'No Venue'
        addr = if atn.address? and atn.address?.length then atn.address else 'No Address'
        vnotes = if atn.venue_note? and atn.venue_note.length then atn.venue_note else 'No Venue Note'
        format = if atn.format? and atn.format.length then _.titleize(atn.format) else 'No format'
        outline = if atn.outline? and atn.outline.length then markdown.toHTML(atn.outline) else 'No outline'
        html += '<tr data-event_id="'+atn.event_id+'">
          <td>
            '+host_str+'
          </td>
          <td>
            '+format+'
          </td>
          <td>
            <span>'+atn.what+'</span>
          </td>
          <td>'+place+'</td>
          <td class="event-review-actions">
          <a data-action="reject" href="/api/admin/event_reject?id='+atn.event_id+'" class="button ambassador-button event-button">Reject</a>
          <a data-action="accept" href="/api/admin/event_accept?id='+atn.event_id+'" class="button ambassador-button event-button">Accept</a>
          </td></tr>
          <tr id="event-detail-'+atn.event_id+'" class="event-detail" style="display:none;">
          <td colspan="5">
            <a href="/admin/meetup/'+atn.event_id+'" class="meetup-edit">Edit Meetup</a>
            <b>Host</b>
            <div>'+host_str+'</div>
            <br/>
            <b>Venue</b>
            <div>'+place+'</div>
            <div>'+addr+'</div>
            <div>'+vnotes+'</div>
            <br/>
            <b>Description</b>
            <div>'+atn.descr+'</div>
            <br/>
            <b>Who it\'s for</b>
            <div>'+atn.who+'</div>
            <br/>
            <b>Happening</b>
            <div>'+moment.utc(atn.start).format('MMMM Do [at] h:mm a')+'</div>
            <br>
            <b>Capacity</b>
            <div>'+atn.max+'</div>
            <b>Outline</b>
            <div>'+outline+'</div>
            <br/>
          </td>
          </tr>'
      html += '<tr class="tbl-head"><th>Meetup</th><th>Venue</th><th>Actions</th></tr>'
      $('#event-review-results').html(html)
      $('#event-start').hide()
      $('#event-review-results-shell').show()

  review: (e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    action = el.data('action')
    str = _.titleize(action)
    event_id = el.closest('tr').data('event_id')
    btn = _.btn(el, str+'ing', str+'ed')
    ap.api 'get admin/event_'+action, {event_id: event_id}, (rsp) ->
      btn.finish()
      setTimeout ->
        el.closest('tr').remove()
        $('#event-detail-'+event_id).remove()
      , 500
    return false

  row_click: (e) ->
    $(e.currentTarget).next('tr').toggle()
