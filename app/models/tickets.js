const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');
const __users = require('./users');
const User = __users[0];
const Users = __users[1];

const Ticket = Shelf.Model.extend({
  tableName: 'tickets',
  idAttribute: 'ticket_id',
  hasTimestamps: true,
});

const Tickets = Shelf.Collection.extend({
  model: Ticket,
  async getUser() {
    const user = await Users.forge({ user_id: this.user_id }).fetch();
    return user;
  },
  async cancelTicket() {
    const yr = 'attending' + process.yr;
    const originalStatus = this.get('status');
    const saveResult = await this.set({ status: 'canceled' }).save();
    if (originalStatus === 'active') {
      const user = await this.getUser();
      const userRes = await user.set({ [yr]: '-1' }).save();
      user.removeFromList('WDS ' + process.year + ' Attendees').then(() => {
        user.addToList('WDS ' + process.year + ' Canceled');
      });
      return [user, this];
    }
    return [null, this];
  },
});

module.exports = [Ticket, Tickets];
