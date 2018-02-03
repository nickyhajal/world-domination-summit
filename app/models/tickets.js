const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const Ticket = Shelf.Model.extend({
  tableName: 'tickets',
  idAttribute: 'ticket_id',
  hasTimestamps: true,

  async getUser() {
    const [User, Users] = require('../models/users');
    const user = await User.forge({ user_id: this.get('user_id') }).fetch();
    return user;
  },

  // These are called by the admin/graphql
  // when purchasing/transferring it happens in user->tickets,
  // but maybe that's stupid
  async cancel() {
    const yr = 'attending' + process.yr;
    const originalStatus = this.get('status');
    const saveResult = await this.set({ status: 'canceled' }).save();
    if (originalStatus === 'active') {
      const user = await this.getUser();
      const userRes = await user.syncAttending();
      if (userRes.get('attending' + process.yr) !== '1') {
        user.removeFromList('WDS ' + process.year + ' Attendees').then(rsp => {
          user.addToList('WDS ' + process.year + ' Canceled');
        });
      }
      return [user, this];
    }
    return [null, this];
  },
  async activate() {
    const yr = 'attending' + process.yr;
    const originalStatus = this.get('status');
    const saveResult = await this.set({ status: 'active' }).save();
    const user = await this.getUser();
    const userRes = await user.syncAttending();
    if (userRes.get('attending' + process.yr) === '1') {
      user.removeFromList('WDS ' + process.year + ' Canceled').then(rsp => {
        user.addToList('WDS ' + process.year + ' Attendees');
      });
    }
    return [user, this];
    return [user, this];
  },
  async updateStatus(newStatus) {
    let row = false;
    switch (newStatus) {
      case 'canceled':
        row = await this.cancel();
        break;
      case 'unclaimed':
        row = await this.set('status', 'unclaimed').save();
        break;
      case 'active':
        row = await this.activate();
        break;
    }
    return row;
  },
});

const Tickets = Shelf.Collection.extend({
  model: Ticket,
});

module.exports = [Ticket, Tickets];
