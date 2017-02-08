Q = require('q')
async = require('async')

##

[Ticket, Tickets] = require '../tickets'
[User, Users] = require '../users'

ticket =
  registerTicket: (quantity = 1, total) ->
    dfr = Q.defer()
    ticket_ids = []
    async.each [0..quantity-1], (i, cb) =>
      Ticket.forge
        type: '360'
        user_id: @get('user_id')
        purchaser_id: @get('user_id')
        status: 'unclaimed'
        year: '2017'
      .save()
      .then (ticket) =>
        ticket_ids.push ticket.get('ticket_id')
        cb()
    , =>
      @addToList('WDS 2017 Purchasers')
      .then =>
        promo = 'TicketReceipt'
        subject = "Aw yeah! Your purchase was successful!"
        tickets = 'ticket'
        tickets = 'tickets' if (quantity > 1)
        params =
          quantity: quantity
          price: (total/100)
          claim_url: 'https://worlddominationsummit.com/claim/'+@get('hash')
          tickets: tickets
        @sendEmail(promo, subject, params)
      dfr.resolve(ticket_ids)
    , (err) ->
      console.error err
    return dfr.promise
  # registerTicket: (eventbrite_id, returning = false, transfer_from = null) ->
  #   dfr = Q.defer()
  #   Ticket.forge
  #     eventbrite_id: eventbrite_id
  #     user_id: @get('user_id')
  #     year: process.year
  #     transfer_from: transfer_from
  #   .save()
  #   .then (ticket) =>
  #     @addToList('WDS '+process.year+ ' Attendees')
  #     .then =>
  #       promo = 'Welcome'
  #       subject = "You're coming to WDS! Awesome!"
  #       if returning
  #         promo = 'WelcomeBack'
  #    #   @sendEmail(promo, subject)
  #   , (err) ->
  #     console.error err
  #   return dfr.promise

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

  assignTicket: (ticket, returning = false, purchaser = null) ->
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
          promo = 'WelcomeAssignee'
          subject = "You're coming to WDS! Awesome!"
          if type is 'connect'
            promo = 'WelcomeConnectAssignee'
          @sendEmail(promo, subject, {purchaser: purchaser.getFullName()})
          purchaser.sendEmail('TicketAssignConfirmation', 'Great, your ticket was assigned!', {assignee: @getFullName()})
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
