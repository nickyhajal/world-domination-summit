const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Ticket, Tickets] = require('../models/tickets');
const [Transaction, Transactions] = require('../models/transactions');
const TransactionGraph = require('./transactions');

module.exports = new GraphQLObjectType({
  name: 'User',
  description: 'User',
  fields: () => {
    const TransactionGraphType = require('./TransactionGraphType');
    const TicketGraphType = require('./TicketGraphType');
    return {
      user_id: { type: GraphQLString },
      hash: { type: GraphQLString },
      attending14: { type: GraphQLInt },
      attending15: { type: GraphQLInt },
      attending16: { type: GraphQLInt },
      attending17: { type: GraphQLInt },
      attending18: { type: GraphQLInt },
      pre18: { type: GraphQLInt },
      ticket_type: { type: GraphQLString },
      type: { type: GraphQLString },
      email: { type: GraphQLString },
      first_name: { type: GraphQLString },
      last_name: { type: GraphQLString },
      user_name: {
        type: GraphQLString,
        resolve: row => {
          const u = row.user_name;
          if (u === undefined) return '';
          return u.length === 40 ? '' : u;
        },
      },
      password: {
        type: GraphQLBoolean,
        resolve: row => {
          const pw = row.password;
          return pw !== undefined && pw && pw.length;
        },
      },
      email_hash: { type: GraphQLString },
      site: { type: GraphQLString },
      facebook: { type: GraphQLString },
      twitter: { type: GraphQLString },
      instagram: { type: GraphQLString },
      location: { type: GraphQLString },
      lat: { type: GraphQLString },
      lon: { type: GraphQLString },
      distance: { type: GraphQLString },
      academy: { type: GraphQLString },
      location: { type: GraphQLString },
      address: { type: GraphQLString },
      address2: { type: GraphQLString },
      city: { type: GraphQLString },
      region: { type: GraphQLString },
      zip: { type: GraphQLString },
      country: { type: GraphQLString },
      calling_code: { type: GraphQLString },
      phone: { type: GraphQLString },
      accomodation: { type: GraphQLString },
      intro: { type: GraphQLString },
      size: { type: GraphQLString },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
      transactions: {
        type: new GraphQLList(TransactionGraphType),
        resolve: async row => {
          const ts = await Transactions.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
            })
            .fetch();
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
        },
      },
      tickets: {
        type: new GraphQLList(TicketGraphType),
        resolve: async row => {
          const ts = await Tickets.forge()
            .query(qb => {
              qb.where('user_id', row.user_id);
              qb.orWhere('purchaser_id', row.user_id);
            })
            .fetch();
          return ts.map(v => (v.attributes !== undefined ? v.attributes : {}));
        },
      },
    };
  },
});
