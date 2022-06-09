Shelf = require('./shelf')
_ = require('underscore')
Q = require('q')
chance = require('chance')()
redis = require("redis")
rds = redis.createClient()
async = require('async')

[Transfer, Transfers] = require('./transfers')
[Transaction, Transactions] = require('./transactions')
[Ticket, Tickets] = require('./tickets')
[Booking, Bookings] = require('./bookings')
[EventRsvp, EventRsvps] = require('./event_rsvps')


postProcessTicket = (transaction, meta, year, wave, presale = false) ->
  [User, Users] = require('./users')
  dfr = Q.defer()
  User.forge
    user_id: transaction.get('user_id')
  .fetch()
  .then (user) ->
    user.registerTicket(transaction.get('quantity'), transaction.get('paid_amount'))
    .then (tickets) ->
      if presale
        process.fire.database().ref().child('presales/').push
          user_id: user.get('user_id')
          name: user.get('first_name')+' '+user.get('last_name')
          created_at: (+(new Date()))
      Tickets.forge().query (qb) ->
        qb.where('year', year)
        qb.where('type', '360')
        qb.whereIn('status', ['active', 'unclaimed'])
      .fetch()
      .then (rsp) ->
        process.fire.database().ref().child('state/'+wave+'/sold').set(rsp.models.length)
      , (err) ->
        console.err(error)
      transaction.set('meta', JSON.stringify(tickets))
      transaction.save()
      dfr.resolve({rsp: {tickets: tickets, user: user}})
  dfr.resolve({})
  return dfr.promise

Product = Shelf.Model.extend
  tableName: 'products'
  idAttribute: 'product_id'
  hasTimestamps: true
  permittedAttributes: [
    'product_id', 'name', 'descr', 'cost', 'sales'
  ]
  pre_process: (meta = false) ->
    dfr = Q.defer()
    if PRE[@get('code')]?
      PRE[@get('code')](meta)
      .then (transfer_id) ->
        dfr.resolve(transfer_id)
    else
      dfr.resolve()
    return dfr.promise

  post_process: (meta = false) ->
    dfr = Q.defer()
    if POST[@get('code')]?
      POST[@get('code')](meta)
      .then (data) ->
        dfr.resolve(data)
    else
      dfr.resolve()
    dfr.promise

Products = Shelf.Collection.extend
  model: Product

PRE =
  academy: (meta) ->
    dfr = Q.defer()
    [User, Users] = require('./users')
    User.forge
      user_id: meta.user_id
    .fetch()
    .then (user) ->
      rsp = {meta: meta.post.event_id}
      if user? and parseInt(user.get('attending'+process.yr)) is 1
        rsp.price = 4900
        # rsp.price = 50
      dfr.resolve(rsp)
    return dfr.promise
  event: (meta) ->
    dfr = Q.defer()
    [User, Users] = require('./users')
    [Event, Events] = require('./events')
    User.forge
      user_id: meta.user_id
    .fetch()
    .then (user) ->
      Event.forge
        event_id: meta.post.event_id
      .fetch()
      .then (ev) ->
        rsp = {meta: meta.post.event_id}
        if ev.get('price')? and ev.get('price') > 0
          rsp.price = ev.get('price')
          # rsp.price = 50
        dfr.resolve(rsp)
    return dfr.promise
  wds17test: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  trex: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2017: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds18test: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2018: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2019: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2020: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2019plan: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wds2020plan: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  wdsDouble: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  hotelbunk: (meta) ->
    dfr = Q.defer()
    Bookings.forge().isTypeSoldOut('bunk')
    .then (isSoldOut) ->
      dfr.resolve({error: if isSoldOut then  'Oh no, all the bunks have sold out!' else false})
    return dfr.promise
  hotelroom: (meta) ->
    dfr = Q.defer()
    Bookings.forge().isTypeSoldOut('room')
    .then (isSoldOut) ->
      dfr.resolve({error: if isSoldOut then  'Oh no, all the standard rooms have sold out!' else false})
    return dfr.promise
  hotelsuite: (meta) ->
    dfr = Q.defer()
    Bookings.forge().isTypeSoldOut('suite')
    .then (isSoldOut) ->
        dfr.resolve({error: if isSoldOut then  'Oh no, all the suites have sold out!' else false})
    .catch ->
        throw ("oh no")
    return dfr.promise
  mealsandwich: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  mealveggie: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  mealchicken: (meta) ->
    dfr = Q.defer()
    dfr.resolve({})
    return dfr.promise
  xfer: (meta) ->
    dfr = Q.defer()
    Transfer.forge
      new_attendee: JSON.stringify(_.omit(meta.post, ['quantity']))
      user_id: meta.user_id
      year: process.year
      status: 'pending'
    .save()
    .then (transfer) ->
      dfr.resolve
        meta: transfer.get('transfer_id')
    , (err) ->
      console.error(err)
    return dfr.promise
  connect: (meta) ->
    dfr = Q.defer()
    quantity = if meta.post.quantity and +meta.post.quantity then +meta.post.quantity else 1
    ids = []
    arr = [0...quantity]
    async.eachSeries arr, (i, cb) ->
      Ticket.forge
        type: 'connect'
        stripe_id: meta.post.transaction_id
        year: process.tkyear
        user_id: meta.user_id
        purchaser_id: meta.user_id
        status: 'pending'
      .save()
      .then (ticket) =>
        ids.push ticket.get('ticket_id')
        cb()
    , ->
      dfr.resolve {meta: JSON.stringify(ids)}
    return dfr.promise

POST =
  academy: (transaction, meta) ->
    tk 'Product: Academy'
    [Event, Events] = require('./events')
    dfr = Q.defer()
    event_id = transaction.get('meta')
    user_id = transaction.get('user_id')
    rsvp = EventRsvp.forge
      user_id: user_id
      event_id: event_id
    rsvp.fetch()
    .then (existing) ->
      if existing
        dfr.resolve({rsvp_id: existing.get('rsvp_id')})
      else
        rsvp.save()
        .then (newrsvp) ->
          dfr.resolve({rsvp_id: newrsvp.get('rsvp_id')})
          Event.forge
            event_id: event_id
          .fetch()
          .then (ev) ->
            ev.updateRsvpCount()
            rds.expire('rsvps_'+user_id, 0)
            tk 'Academy Conf from Prod'
            ev.sendAcademyConfirmation(user_id, '$'+(transaction.get('paid_amount') / 100))
    return dfr.promise

  event: (transaction, meta) ->
    tk 'Product: Event'
    [User, Users] = require('./users')
    [Event, Events] = require('./events')
    dfr = Q.defer()
    event_id = transaction.get('meta')
    user_id = transaction.get('user_id')
    rsvp = EventRsvp.forge
      user_id: user_id
      event_id: event_id
    rsvp.fetch()
    .then (existing) ->
      if existing
        dfr.resolve({rsvp_id: existing.get('rsvp_id')})
      else
        rsvp.save()
        .then (newrsvp) ->
          dfr.resolve({rsvp_id: newrsvp.get('rsvp_id')})
          Event.forge
            event_id: event_id
          .fetch()
          .then (ev) ->
            ev.updateRsvpCount()
            tk 'RSVP Conf from Prod'
            ev.sendRsvpConfirmation(user_id, '$'+(transaction.get('paid_amount') / 100))
            rds.expire('rsvps_'+user_id, 0)
    return dfr.promise

  trex: (transaction, meta) ->
    tk 'Product: Trex'
    [User, Users] = require('./users')
    [Event, Events] = require('./events')
    dfr = Q.defer()
    event_id = 2012
    user_id = transaction.get('user_id')
    quantity = transaction.get('quantity')
    rsvps = []
    rsvp = EventRsvp.forge
      user_id: user_id
      event_id: event_id

    finish = (sendBack) ->
      Event.forge
        event_id: event_id
      .fetch()
      .then (ev) ->
        ev.updateRsvpCount()
        ev.sendRsvpConfirmation(user_id, '$'+(transaction.get('paid_amount') / 100))
        Transactions.forge()
        .query('where', 'product_id', '2012')
        .query('where', 'status', 'paid')
        .fetch()
        .then (xs) ->
          total = 0
          xs.each (x) ->
            total += +x.get('quantity')
          process.fire.database().ref().child('state/trex/tickets_sales').set(total)
          rds.expire('rsvps_'+user_id, 0)
          dfr.resolve(sendBack)
    rsvp.fetch()
    .then (existing) ->
      if existing
        finish({rsvp_id: existing.get('rsvp_id')})
        dfr.resolve()
      else
        rsvp.save()
        .then (rsp) ->
          finish({rsvp_id: rsp.get('rsvp_id')})
          
    return dfr.promise

  wds17test: (transaction, meta) ->
    [User, Users] = require('./users')
    dfr = Q.defer()
    User.forge
      user_id: transaction.get('user_id')
    .fetch()
    .then (user) ->
      user.registerTicket(transaction.get('quantity'), transaction.get('paid_amount'))
      .then (tickets) ->
        process.fire.database().ref().child('presales/').push
          user_id: user.get('user_id')
          name: user.get('first_name')+' '+user.get('last_name')
          created_at: (+(new Date()))
        Tickets.forge().query (qb) ->
          qb.where('year', '2018')
          qb.where('type', '360')
        .fetch()
        .then (rsp) ->
          process.fire.database().ref().child('state/sales_wave1_2020/sold').set(rsp.models.length)
        , (err) ->
          console.err(error)
        transaction.set('meta', JSON.stringify(tickets))
        transaction.save()
        dfr.resolve({rsp: {tickets: tickets, user: user}})
    dfr.resolve({})
    return dfr.promise

  wds2019: (transaction, meta) -> return postProcessTicket(transaction, meta, '2019', 'sales_wave1_2020')
  wds2020: (transaction, meta) -> return postProcessTicket(transaction, meta, '2020', 'sales_wave1_2020', true)
  wds2019plan: (transaction, meta) -> 
    dfr = Q.defer()
    postProcessTicket(transaction, meta, '2019', 'sales_wave1_2020')
    .then ->
      [User, Users] = require('./users')
      User.forge
        user_id: transaction.get('user_id')
      .fetch()
      .then (user) ->
        stripe = require('stripe')(process.env.STRIPE_SK)
        pkg = {
          customer: user.get('stripe'),
          items: [{ plan: process.env.STRIPE_PLAN_ID, quantity: +transaction.get('quantity') }],
          metadata: {installments_paid: 1},
          trial_from_plan: true
        }
        stripe.subscriptions.create(pkg).then (created) ->
          transaction.set({subscription_type: 'create_subscription', subscription_id: created.id})
          transaction.save();
          user.set({plan_installments: 1})
          user.save();
          dfr.resolve({})
        .catch(e) ->
          dfr.resolve({})
          console.error(e)
    return dfr.promise
  wds2020plan: (transaction, meta) -> 
    dfr = Q.defer()
    postProcessTicket(transaction, meta, '2020', 'sales_wave1_2020')
    .then ->
      [User, Users] = require('./users')
      User.forge
        user_id: transaction.get('user_id')
      .fetch()
      .then (user) ->
        stripe = require('stripe')(process.env.STRIPE_SK)
        pkg = {
          customer: user.get('stripe'),
          items: [{ plan: process.env.STRIPE_PLAN_ID, quantity: +transaction.get('quantity') }],
          metadata: {installments_paid: 1},
          trial_from_plan: true
        }
        stripe.subscriptions.create(pkg).then (created) ->
          transaction.set({subscription_type: 'create_subscription', subscription_id: created.id})
          transaction.save();
          user.set({plan_installments: 1})
          user.save();
          dfr.resolve({})
        .catch(e) ->
          dfr.resolve({})
          console.error(e)
    return dfr.promise

  wdsDouble: (transaction, meta) ->
    [User, Users] = require('./users')
    dfr = Q.defer()
    User.forge
      user_id: transaction.get('user_id')
    .fetch()
    .then (user) ->
      user.registerTicket(transaction.get('quantity'), transaction.get('paid_amount'), null, true)
      .then (tickets) ->
        process.fire.database().ref().child('presales/').push
          user_id: user.get('user_id')
          name: user.get('first_name')+' '+user.get('last_name')
          created_at: (+(new Date()))
        Tickets.forge().query (qb) ->
          qb.where('year', '2020')
          qb.where('type', '360')
          qb.whereIn('status', ['active', 'unclaimed'])
        .fetch()
        .then (rsp) ->
          process.fire.database().ref().child('state/sale_pre_2020/sold').set(rsp.models.length)
        , (err) ->
          console.err(error)
        Tickets.forge().query (qb) ->
          qb.where('year', '2019')
          qb.where('type', '360')
          qb.whereIn('status', ['active', 'unclaimed'])
        .fetch()
        .then (rsp) ->
          process.fire.database().ref().child('state/sale_pre_2019/sold').set(rsp.models.length)
        , (err) ->
          console.err(error)
        transaction.set('meta', JSON.stringify(tickets))
        transaction.save()
        dfr.resolve({rsp: {tickets: tickets, user: user}})
    dfr.resolve({})
    return dfr.promise

  xfer: (transaction, meta) ->
    [User, Users] = require('./users')
    dfr = Q.defer()
    transfer_id = transaction.get('meta')
    Transfer.forge
      transfer_id: transfer_id
    .fetch()
    .then (xfer) ->
      new_attendee = JSON.parse(xfer.get('new_attendee'))
      delete new_attendee.transaction_id
      new_attendee['attending'+process.yr] = '1'
      User.forge(new_attendee)
      .markAsTransfer(xfer.get('transfer_id'))
      .save()
      .then (new_user) ->
        uniqid = +(new Date()) + ''
        new_user.processAddress()
        User.forge({user_id: xfer.get('user_id')})
        .fetch()
        .then (old_user) ->
          ticket_type = old_user.get('ticket_type')
          new_user.set('ticket_type', ticket_type)
          new_user.save()
          old_user.cancelTicket()
          old_user.sendEmail('transfer-receipt', 'Your ticket transfer was successful!', {to_name: new_user.get('first_name')+' '+new_user.get('last_name')})
          xfer.set
            status: 'paid'
            to_id: new_user.get('user_id')
          .save()
          .then ->
            dfr.resolve({rsp: {transfer_id: xfer.get('transfer_id')}})
      , (err) ->
        console.error err
    dfr.promise
  connect: (transaction, meta) ->
    [User, Users] = require('./users')
    dfr = Q.defer()
    ids = JSON.parse(transaction.get('meta'))
    tickets = []
    user = false

    # Get the transaction user
    User.forge
      user_id: transaction.get('user_id')
    .fetch()
    .then (user) ->
      async.eachSeries ids, (id, cb) ->
        # Create the tickets
        Ticket.forge
          ticket_id: id
        .fetch()
        .then (ticket) =>
          ticket.set 'status', 'unclaimed'
          ticket.save()
          tickets.push(ticket)
          cb()
      , ->
        params =
          price: transaction.get('paid_amount')/100
          tickets: if transaction.get('quantity') == 1 then 'ticket' else 'tickets'
          quantity: transaction.get('quantity')
        user.sendEmail('ConnectReceipt', "Aw yeah! Your purchase was successful!", params)
        dfr.resolve({rsp: {tickets: tickets.toString() }})
    return dfr.promise
  t360: (meta) ->
    Ticket.forge
      stripe_id: meta.id,
      year: process.tkyear
      hash: chance.string({pool: 'abcdefghijklmnopqrstuvwxyz', length:6})
      meta_data: JSON.stringify
        shipping: meta.shipping
        source: meta.source
    .save()
    .then (ticket) ->
      res.r.ticket_success = true
      res.r.ticket = ticket
      next()
  hotelbunk: (transaction, meta) ->
    dfr = Q.defer()
    Booking.forge
      user_id: transaction.get('user_id')
      type: 'bunk'
      status: 'active'
    .save()
    .then (booking) ->
      booking.sendConfirmation()
      Bookings.forge().numOfType('bunk')
      .then (num) ->
        process.fire.database().ref().child('state/hotels/bunk_sales').set(num)
      dfr.resolve({})
    return dfr.promise
  hotelroom: (transaction, meta) ->
    dfr = Q.defer()
    Booking.forge
      user_id: transaction.get('user_id')
      type: 'room'
      status: 'active'
    .save()
    .then (booking) ->
      booking.sendConfirmation()
      Bookings.forge().numOfType('room')
      .then (num) ->
        process.fire.database().ref().child('state/hotels/room_sales').set(num)
      dfr.resolve({})
    return dfr.promise
  hotelsuite: (transaction, meta) ->
    dfr = Q.defer()
    Booking.forge
      user_id: transaction.get('user_id')
      type: 'suite'
      status: 'active'
    .save()
    .then (booking) ->
      booking.sendConfirmation()
      Bookings.forge().numOfType('suite')
      .then (num) ->
        process.fire.database().ref().child('state/hotels/suite_sales').set(num)
      dfr.resolve({})
    return dfr.promise
  mealsandwich: (meta) ->
    dfr = Q.defer()
    Transactions.forge().query('where', 'product_id', '18').query('where', 'status', 'paid').fetch().then (rows) ->
      process.fire.database().ref().child('state/meals/sandwich_sales').set(rows.length)
      dfr.resolve({})
    return dfr.promise
  mealchicken: (meta) ->
    dfr = Q.defer()
    Transactions.forge().query('where', 'product_id', '19').query('where', 'status', 'paid').fetch().then (rows) ->
      process.fire.database().ref().child('state/meals/chicken_sales').set(rows.length)
      dfr.resolve({})
    return dfr.promise
  mealveggie: (meta) ->
    dfr = Q.defer()
    Transactions.forge().query('where', 'product_id', '20').query('where', 'status', 'paid').fetch().then (rows) ->
      process.fire.database().ref().child('state/meals/veggie_sales').set(rows.length)
      dfr.resolve({})
    return dfr.promise


module.exports = [Product, Products]

