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
const UserGraph = require('./users');

const Type = new GraphQLObjectType({
  name: 'Ticket',
  description: 'Ticket Type',
  fields: () => ({
    ticket_id: { type: GraphQLString },
    user_id: { type: GraphQLInt },
    purchaser_id: { type: GraphQLInt },
    status: { type: GraphQLString },
    year: { type: GraphQLInt },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    user: {
      type: UserGraph.Type,
      resolve: async row => {
        const u = await User.forge({
          user_id: row.user_id,
        }).fetch();
        return u.attributes;
      },
    },
    purchaser: {
      type: UserGraph.Type,
      resolve: async row => {
        const u = await User.forge({
          user_id: row.purchaser_id,
        }).fetch();
        return u.attributes;
      },
    },
  }),
});
module.exports = {
  Type,
};
