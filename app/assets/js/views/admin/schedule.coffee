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
      for ev in rsp.events
        start = moment.utc(ev.start)
        if start.format('D') isnt lastDay
          html += '<tr class="search-mid-heading"><th colspan="10">Aug. '+start.format('Do')+'</th></tr>'
          lastDay = start.format('D')
        html += '<tr class="event-row" data-event_id="'+ev.event_id+'">
          <td>'+start.format('h:mm a')+'</td>
          <td>
            <span>'+ev.what+'</span>
          </td>
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
