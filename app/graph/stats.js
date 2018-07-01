const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLBoolean,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const moment = require('moment');
const [Ticket, Tickets] = require('../models/tickets');
const [Transaction, Transactions] = require('../models/transactions');
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
      single_buys: { type: GraphQLInt },
      double_buys: { type: GraphQLInt },
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
      double_buys: 0,
      single_buys: 0,
    };
    const doubleBuys = await Transactions.query(qb => {
      qb.where('product_id', '16');
      qb.where('paid_amount', '>', '10000');
    }).fetch();
    const singleBuys = await Transactions.query(qb => {
      qb.where('product_id', '15');
      qb.where('paid_amount', '>', '10000');
    }).fetch();
    const row = await Tickets.query(qb => {
      qb.where('year', '2019');
    }).fetch();
    vals.double_buys = doubleBuys.reduce((sum, row) => {
      return sum + +row.quantity;
    }, 0);
    vals.single_buys = singleBuys.reduce((sum, row) => {
      return sum + +row.quantity;
    }, 0);
    row.models.forEach(v => {
      const status = v.get('status');
      if (status === 'active' || status === 'unclaimed') {
        vals.total_tickets += 1;
        if (
          moment(v.get('created_at')).format('YYYY-MM-DD') >
          '2017-10-01 00:00:00'
        ) {
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
