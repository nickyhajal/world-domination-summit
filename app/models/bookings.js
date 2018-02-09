const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const Booking = Shelf.Model.extend({
  tableName: 'bookings',
  idAttribute: 'booking_id',
  hasTimestamps: true,

  sendConfirmation() {
    const [User, Users] = require('./users');
    const type = this.get('type');
    const prices = {
      bunk: '$347',
      room: '$747',
      suite: '$947',
    };
    User.forge({
      user_id: this.get('user_id'),
    })
      .fetch()
      .then(user => {
        user.sendEmail('HotelReceipt', 'Booking Confirmed!', {
          room_type: type.replace('room', 'standard room'),
          total_cost: prices[type],
        });
      });
  },
});

const Bookings = Shelf.Collection.extend({
  model: Booking,
  numOfType: async type => {
    const rsp = await Bookings.forge()
      .query(qb => {
        qb.where('type', type);
        qb.where('status', 'active');
      })
      .fetch();
    return rsp.models.length;
  },
  isTypeSoldOut: async type => {
    const maxes = {
      bunk: 25,
      room: 24,
      suite: 12,
    };
    const numType = await Bookings.forge().numOfType(type);
    return numType >= maxes[type];
  },
});

module.exports = [Booking, Bookings];
