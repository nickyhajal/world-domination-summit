ap.Views.admin_event_review = XView.extend
  timo: 0
  events:
    'click .event-button': 'review'
  initialize: ->
    @initRender()

  rendered: ->
    @listing()

  listing: ->
    ap.api 'get admin/events', {active: 0}, (rsp) ->
      html = ''
      for atn in rsp.events
      #   atn = new ap.Event(atn)
        html += '<tr data-event_id="'+atn.event_id+'">
          <td>
            <span>'+atn.who+'</span>
          </td>
          <td>'+atn.place+'</td>
          <td class="event-review-actions">
          <a data-action="accept" href="/api/admin/event_accept?id='+atn.event_id+'" class="button ambassador-button event-button">Accept</a>
          <a data-action="reject" href="/api/admin/event_reject?id='+atn.event_id+'" class="button ambassador-button event-button">Reject</a>
          </td>'
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
      , 500
