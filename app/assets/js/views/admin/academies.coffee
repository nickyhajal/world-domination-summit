ap.Views.admin_academies = XView.extend
  timo: 0
  events:
    'click .event-row': 'showEvent'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get admin/academies', {}, (rsp) ->
      html = '<tr><td>Time</td><td>Academy</td><td>Free</td><td>Total</td><td></td>'
      lastDay = '0'
      for ev in rsp.events
        start = moment.utc(ev.start)
        if start.format('D') isnt lastDay
          html += '<tr class="search-mid-heading"><th colspan="10">'+start.format('MMM\ Do')+'</th></tr>'
          lastDay = start.format('D')
        html += '<tr class="event-row" data-event_id="'+ev.event_id+'">
          <td>'+start.format('h:mm a')+'</td>
          <td>
            <span>'+ev.what+'</span>
          </td>
          <td>'+ev.num_free+'/'+ev.free_max+'</td>
          <td>'+ev.num_rsvps+'/'+ev.max+'</td>
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
    ap.navigate('admin/academy/'+event_id)
