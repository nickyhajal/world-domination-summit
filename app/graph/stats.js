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
const TicketGraphType = require('./TicketGraphType');

const Type = new GraphQLObjectType({
  name: 'Stats',
  description: 'Stats Type',
  fields: () => {
    return {
      current_wave_tickets: { type: GraphQLInt },
      total_tickets: { type: GraphQLInt },
      num_assigned: { type: GraphQLInt },
      num_started_profile: { type: GraphQLInt },
      num_finished_profile: { type: GraphQLInt },
    };
  },
});
const Field = {
  type: Type,
  resolve: async root => {
    const vals = {
      current_wave_tickets: 0,
      total_tickets: 0,
      num_assigned: 0,
      num_started_profile: 0,
      num_finished_profile: 0,
    };
    const row = await Tickets.query(qb => {
      qb.where('year', '2018');
    }).fetch();
    row.models.forEach(v => {
      const status = v.get('status');
      if (['pending', 'canceled', 'refunded'].indexOf(status) === -1) {
        vals.total_tickets += 1;
        if (v.get('created_at') > '2017-10-01 00:00:00') {
          vals.current_wave_tickets += 1;
        }
      }
      if (status === 'active') {
        vals.num_assigned += 1;
      }
    });
    return vals;
  },
};
module.exports = {
  Type,
  Field,
};
