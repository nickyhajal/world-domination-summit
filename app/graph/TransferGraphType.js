const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');

const TransferType = new GraphQLObjectType({
  name: 'UserTransfer',
  description: 'Transfer',
  fields: () => {
    const UserGraphType = require('./UserGraphType');
    const TransactionGraphType = require('./TransactionGraphType');
    const TicketGraphType = require('./TicketGraphType');
    const [User, Users] = require('../models/users');
    return {
      transfer_id: { type: GraphQLString },
      user_id: { type: GraphQLString },
      to_id: { type: GraphQLString },
      new_attendee: { type: GraphQLString },
      year: { type: GraphQLString },
      status: { type: GraphQLString },
      from: {
        type: UserGraphType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.user_id }).fetch();
          return user !== undefined && user ? user.attributes : {};
        },
      },
      to: {
        type: UserGraphType,
        resolve: async row => {
          const user = await User.forge({ user_id: row.to_id }).fetch();
          return user !== undefined && user ? user.attributes : {};
        },
      },
      ticket: {
        type: TicketGraphType,
        resolve: async row => {
          const [Ticket, Tickets] = require('../models/tickets');
          const ticket = await Ticket.forge({
            user_id: row.to_id,
            year: row.year,
          }).fetch();
          return ticket !== undefined && ticket ? ticket.attributes : {};
        },
      },
      created_at: { type: GraphQLString },
    };
  },
});
module.exports = TransferType;
