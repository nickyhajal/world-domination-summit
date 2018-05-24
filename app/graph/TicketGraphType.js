const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [Ticket, Tickets] = require('../models/tickets');
const [User, Users] = require('../models/users');

module.exports = new GraphQLObjectType({
  name: 'Ticket',
  description: 'Ticket Type',
  fields: () => {
    const UserGraphType = require('./UserGraphType');
    return {
      ticket_id: { type: GraphQLString },
      type: { type: GraphQLString },
      user_id: { type: GraphQLInt },
      purchaser_id: { type: GraphQLInt },
      status: { type: GraphQLString },
      year: { type: GraphQLInt },
      created_at: { type: GraphQLString },
      updated_at: { type: GraphQLString },
      transfer_from: { type: GraphQLString },
      user: {
        type: UserGraphType,
        resolve: async row => {
          const u = await User.forge({
            user_id: row.user_id,
          }).fetch();
          return u && u.attributes !== undefined ? u.attributes : {};
        },
      },
      purchaser: {
        type: UserGraphType,
        resolve: async row => {
          if (row.purchaser_id) {
            const u = await User.forge({
              user_id: row.purchaser_id,
            }).fetch();
            return u && u.attributes !== undefined ? u.attributes : {};
          }
          return {};
        },
      },
    };
  },
});
