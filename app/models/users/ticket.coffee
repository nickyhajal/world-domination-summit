Q = require('q')
async = require('async')

##

[Ticket, Tickets] = require '../tickets'

ticket =
  registerTicket: (quantity = 1, total = 0, transferFrom = null, link20=false) ->
    dfr = Q.defer()
    ticket_ids = []
    type = @get('type')
    ticket_type = @get('ticket_type')
    @set('pre'+process.tkyr,'1').save() #ONLY DURING PRESALE
    if link20
      @set('preDouble', '1').save()
    if (!type || !type.length)
      @set('type','attendee').save()
    if (!ticket_type || !ticket_type.length)
      ticket_type = '360'

    async.each [0..quantity-1], (i, cb) =>
      Ticket.forge
        type: ticket_type
        user_id: @get('user_id')
        purchaser_id: @get('user_id')
        status: 'unclaimed'
        year: process.tkyear
        transfer_from: transferFrom
      .save()
      .then (ticket) =>
        ticket_ids.push ticket.get('ticket_id')
        if link20
          Ticket.forge
            type: ticket_type
            user_id: @get('user_id')
            purchaser_id: @get('user_id')
            linked_id: ticket.get('ticket_id')
            status: 'unclaimed'
            year: '2020'
            transfer_from: transferFrom
          .save()
          .then (ticket20) =>
            ticket_ids.push ticket20.get('ticket_id')
            cb()
        else
          if transferFrom
            promo = 'WelcomeTransfer'
            subject = "You're coming to WDS! Awesome!"
            @sendEmail(promo, subject)
          cb()
    , =>
      if total > 0
        if link20
          @addToList('WDS 2020 Purchasers').then()
          @addToList('WDS 2020 Pre-Orders').then()
          @addToList('WDS 2019 and 2020 Pre-Orders').then()
        @addToList('WDS 2019 Pre-Orders').then()
        @addToList('WDS 2019 Purchasers')
        .then =>
          promo = if link20 then 'TicketDoubleReceipt' else 'TicketReceipt'
          subject = "Aw yeah! Your purchase was successful!"
          tickets = 'ticket'
          tickets = 'tickets' if (quantity > 1)
          params =
            quantity: quantity
            price: (total/100)
            claim_url: 'https://worlddominationsummit.com/assign/'+@get('hash')
            tickets: tickets
          @sendEmail(promo, subject, params)
      dfr.resolve(ticket_ids)
    , (err) ->
      console.error err
    return dfr.promise

  transferTicket: (transfer_from = null) ->
    dfr = Q.defer()
    Ticket.forge
      user_id: @get('user_id')
      year: process.tkyear
      transfer_from: transfer_from
    .save()
    .then (ticket) =>
      @addToList('WDS '+process.tkyear+ ' Attendees')
      .then =>
        promo = 'Welcome'
        subject = "You're coming to WDS! Awesome!"
        @sendEmail(promo, subject)
    return dfr.promise

  connectTicket: (ticket, returning = false, transfer_from = null) ->
    [User, Users] = require '../users'
    tk "CLAIM IT"
    yr = process.tkyr
    year = process.tkyear
    dfr = Q.defer()
    type = ticket.get('type')
    ticket.set
      status: 'active'
      user_id: @get('user_id')
    .save()
    .then (upd_ticket) =>
      tk 'CLAIMED'
      user = User.forge(@attributes)
      user.set 'attending'+process.tkyr, '1' #+process.yr, '1'
      user.set 'ticket_type', type
      user.save()
      .then (upd_user) =>
        list = 'WDS '+year+' Attendees'
        # list = 'WDS 2018 Attendees'
        if type is 'connect'
          list = 'WDS '+year+' Connect'
        @addToList(list)
        .then =>
          promo = 'Welcome'
          subject = "You're coming to WDS! Awesome!"
          # if returning
          #   promo = 'WelcomeBack'
          if type is 'connect'
            promo = 'WelcomeConnect'
          @sendEmail(promo, subject)
          dfr.resolve({user: upd_user, ticket: upd_ticket})
    , (err) ->
      console.error err
    return dfr.promise

  assignTicket: (ticket, returning = false, purchaser = null) ->
    dfr = Q.defer()
    yr = process.tkyr
    year = process.tkyear
    type = ticket.get('type')
    ticket.set
      status: 'active'
      user_id: @get('user_id')
    .save()
    .then (upd_ticket) =>
      boughtMonth = ticket.get('created_at').getMonth()+1
      if [6,7,8].indexOf(boughtMonth) > -1
        @set 'pre'+yr, '1'
      @set 'attending'+yr, '1'
      @set 'ticket_type', type
      @save()
      .then (upd_user) =>
        list = 'WDS '+year+' Attendees'
        if type is 'connect'
          list = 'WDS '+year+' Connect'
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
    yr = 'attending'+process.tkyr
    if (@get(yr) != '-1')
      @set(yr, '-1')
      .save()
    Ticket.forge
      user_id: @get('user_id')
      year: process.tkyear
    .fetch()
    .then (ticket) =>
      if ticket
        ticket.set
          status: 'canceled'
        .save()
        .then =>
          @removeFromList('WDS '+process.tkyear+' Attendees')
          .then =>
            @addToList('WDS '+process.tkyear+' Canceled')
            dfr.resolve [this, ticket]
        , (err) ->
          console.error err
      else
        console.error("Doesn't have a ticket.'")
        # dfr.resolve("Doesn't have a ticket.")
    return dfr.promise

module.exports = ticket
