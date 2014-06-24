Q = require('q')

##

[Ticket, Tickets] = require '../tickets'

ticket =
  registerTicket: (eventbrite_id, returning = false, transfer_from = null) ->
    dfr = Q.defer()
    Ticket.forge
      eventbrite_id: eventbrite_id
      user_id: @get('user_id')
      year: process.year
      transfer_from: transfer_from
    .save()
    .then (ticket) =>
      @addToList('WDS '+process.year+ ' Attendees')
      .then =>
        promo = 'Welcome'
        subject = "You're coming to WDS! Awesome! Now... Create your profile!"
        if returning
          promo = 'WelcomeBack'
        @sendEmail(promo, subject)
    , (err) ->
      tk err
    return dfr.promise

  cancelTicket: ->
    dfr = Q.defer()
    @set('attending'+process.yr, '-1')
    .save()
    .then =>
      Ticket.forge
        user_id: @get('user_id')
        year: process.year
      .fetch()
      .then (ticket) =>
        if ticket
          ticket.set
            status: 'canceled'
          save()
          .then =>
            @removeFromList('WDS '+process.year+' Attendees')
            .then =>
              @addToList('WDS '+process.year+' Canceled')
              dfr.resolve [this, ticket]
        dfr.reject("Doesn't have a ticket.")
    return dfr.promise

module.exports = ticket
