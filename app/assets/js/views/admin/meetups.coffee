ap.Views.admin_meetups = XView.extend
  timo: 0
  events:
    'click #event-review-results tr': 'row_click'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get admin/events', {active: 1, type: 'meetup'}, (rsp) ->
      _.whenReady 'users', =>
        html = '<tr class="tbl-head"><th>Host</th><th>Meetup</th><th>Venue</th></tr>'
        for atn in rsp.events
          host = ''
          if ap.Users.get(atn.hosts[0])
            host = ap.Users.get(atn.hosts[0])
            host = host.get('first_name')+' '+host.get('last_name')
          place = if atn.place.length then atn.place else 'No Venue'
          html += '
          <tr data-event_id="'+atn.event_id+'">
            <td>'+host+'</td>
            <td>
              <span>'+atn.what+'</span>
            </td>
            <td>'+place+'</td>
          </tr>
        '
        html += '<tr class="tbl-head"><th>Host</th><th>Meetup</th><th>Venue</th></tr>'
        $('#event-review-results').html(html)
        $('#event-start').hide()
        $('#event-review-results-shell').show()

  row_click: (e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    event_id = el.closest('tr').data('event_id')
    ap.navigate('admin/meetup/'+event_id)
    return false
