const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const StripeEvent = Shelf.Model.extend({
  tableName: 'stripe_events',
  idAttribute: 'stripe_event_id',
  hasTimestamps: true,
});

const StripeEvents = Shelf.Collection.extend({
  model: StripeEvent,
});

module.exports = [StripeEvent, StripeEvents];
