Q = require('q')
async = require('async')

##

[Ticket, Tickets] = require '../tickets'

ticket =
  preregisterTicket: (quantity = 1) ->
    dfr = Q.defer()
    ticket_ids = []
    @set('pre17', '1')
    async.each [0..quantity], (i, cb) ->
      Ticket.forge
        type: '360'
        eventbrite_id: eventbrite_id
        user_id: @get('user_id')
        purchaser_id: @get('user_id')
        year: (process.year+1)
      .save()
      .then (ticket) =>
        ticket_ids.push ticket.get('ticket_id')
        cb()
    , ->
      dfr.resolve(ticket_ids)
      @addToList('WDS '+(process.year+1)+ ' Attendees')
      .then =>
        promo = 'preorder'
        subject = "You're coming to WDS 2017! Awesome!"
       #   @sendEmail(promo, subject)
    , (err) ->
      console.error err
    return dfr.promise
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
        subject = "You're coming to WDS! Awesome!"
        if returning
          promo = 'WelcomeBack'
     #   @sendEmail(promo, subject)
    , (err) ->
      console.error err
    return dfr.promise

  connectTicket: (ticket, returning = false, transfer_from = null) ->
    dfr = Q.defer()
    type = ticket.get('type')
    ticket.set
      status: 'active'
      user_id: @get('user_id')
    .save()
    .then (upd_ticket) =>
      @set 'attending'+process.yr, '1'
      @set 'ticket_type', type
      @save()
      .then (upd_user) =>
        list = 'WDS '+process.year+' Attendees'
        if type is 'connect'
          list = 'WDS '+process.year+' Connect'
        @addToList(list)
        .then =>
          promo = 'Welcome'
          subject = "You're coming to WDS! Awesome!"
          if returning
            promo = 'WelcomeBack'
          if type is 'connect'
            promo = 'WelcomeConnect'
          # @sendEmail(promo, subject)
          dfr.resolve({user: upd_user, ticket: upd_ticket})
    , (err) ->
      console.error err
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
          .save()
          .then =>
            @removeFromList('WDS '+process.year+' Attendees')
            .then =>
              @addToList('WDS '+process.year+' Canceled')
              dfr.resolve [this, ticket]
          , (err) ->
            console.error err
        else
          dfr.reject("Doesn't have a ticket.")
    return dfr.promise

module.exports = ticket
