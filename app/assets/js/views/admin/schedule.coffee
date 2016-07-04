ap.Views.admin_schedule = XView.extend
  timo: 0
  events:
    'click .event-row': 'showEvent'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get admin/schedule', {}, (rsp) ->
      html = ''
      lastDay = '0'
      html += '<tr class="search-mid-heading"><th>Time</th><th>Event</th><th>Type</th><th colspan="10">For</th></tr>'
      for ev in rsp.events
        start = moment.utc(ev.start)
        if start.format('D') isnt lastDay
          html += '<tr class="search-mid-heading"><th colspan="10">'+start.format('dddd')+', Aug. '+start.format('Do')+'</th></tr>'
          lastDay = start.format('D')
        for_type = ev.for_type ? 'all'
        html += '<tr class="event-row" data-event_id="'+ev.event_id+'">
          <td>'+start.format('h:mm a')+'</td>
          <td>
            <span>'+ev.what+'</span>
          </td>
          <td>'+_.titleize(ev.type.replace('_', ' '))+'</td>
          <td>'+_.titleize(for_type)+'</td>
          <td class="search-actions">
            <a href="#" class="button">Edit</a></span>
          </td>
        '
      $('#schedule-results').html(html)
      $('#schedule-start').hide()
      $('#schedule-shell').show()

  showEvent: (e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    event_id = el.data('event_id')
    ap.navigate('admin/event/'+event_id)
