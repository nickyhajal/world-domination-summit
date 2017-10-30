const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const Ticket = Shelf.Model.extend({
  tableName: 'tickets',
  idAttribute: 'ticket_id',
  hasTimestamps: true,

  async cancelTicket() {
    const yr = 'attending' + process.yr;
    const originalStatus = this.get('status');
    const saveResult = await this.set({ status: 'canceled' }).save();
    if (originalStatus === 'active') {
      const user = await this.getUser();
      const userRes = await user.set({ [yr]: '-1' }).save();
      user.removeFromList('WDS ' + process.year + ' Attendees').then(rsp => {
        user.addToList('WDS ' + process.year + ' Canceled');
      });
      return [user, this];
    }
    return [null, this];
  },
  async updateStatus(newStatus) {
    let row = false;
    switch (newStatus) {
      case 'canceled':
        row = await this.cancelTicket();
        break;
    }
    return row;
  },
});

const Tickets = Shelf.Collection.extend({
  model: Ticket,
  async getUser() {
    const [User, Users] = require('../models/users');
    const user = await Users.forge({ user_id: this.user_id }).fetch();
    return user;
  },
});

module.exports = [Ticket, Tickets];
