const Shelf = require('./shelf');
const Bookshelf = require('bookshelf');
const Q = require('q');

const Email = Shelf.Model.extend({
  tableName: 'emails',
  idAttribute: 'email_id',
  hasTimestamps: true,

  async resend() {
    const [User, Users] = require('../models/users');
    let email_id = this.get('email_id');
    const promo = this.get('promo');
    const subject = this.get('promo');
    const data = this.get('data');
    const user_id = this.get('user_id');
    const resent_from = this.get('resent_from');
    const user = await User.forge({ user_id }).fetch();
    if (user) {
      await user.sendEmail(
        promo,
        subject,
        JSON.parse(data),
        resent_from ? resent_from : email_id
      );
    }
  },
});

const Emails = Shelf.Collection.extend({
  model: Email,
});

module.exports = [Email, Emails];
