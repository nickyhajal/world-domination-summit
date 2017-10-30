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
const makeGraphNonNull = require('../util/makeGraphNonNull');

const Type = TicketGraphType;
const PluralType = new GraphQLObjectType({
  name: 'Tickets',
  description: 'Tickets Type',
  fields: () => {
    return {
      tickets: { type: new GraphQLList(Type) },
      pages: { type: GraphQLInt },
      count: { type: GraphQLInt },
    };
  },
});
const Field = {
  type: Type,
  args: {
    id: { type: GraphQLString },
  },
  resolve: async (root, { id }) => {
    const row = await Ticket.forge({ ticket_id: id }).fetch();
    return row.attributes;
  },
};
const Fields = {
  type: PluralType,
  args: {
    order_by: { type: GraphQLString, defaultValue: 'ticket_id' },
    order: { type: GraphQLString, defaultValue: 'DESC' },
    per_page: { type: GraphQLInt, defaultValue: 20 },
    page: { type: GraphQLInt, defaultValue: 0 },
  },
  resolve: async (root, { page, per_page, order_by, order }) => {
    const rows = await Tickets.forge()
      .query(qb => {
        qb
          .limit(per_page)
          .offset(page * per_page)
          .orderBy(order_by, order);
      })
      .fetch();
    let countRes = await process.knex('tickets').count('ticket_id as cnt');
    countRes = countRes[0].cnt;
    return {
      tickets: rows.models.map(row => row.attributes),
      count: countRes,
      pages: countRes / per_page,
    };
  },
};

const Args = {
  ticket_id: { type: GraphQLInt },
  type: { type: GraphQLString },
  user_id: { type: GraphQLInt },
  purchaser_id: { type: GraphQLInt },
  status: { type: GraphQLString },
};

const Update = {
  type: Type,
  args: makeGraphNonNull(Args, ['ticket_id'], 'all'),
  resolve: async (root, { ticket_id, type, user_id, status }) => {
    let row = {};
    const ticket = await Ticket.forge({ ticket_id }).fetch();
    if (status !== undefined) {
      row = ticket.updateStatus(status);
    }
    return row.attributes;
  },
};
const Add = {
  type: Type,
  args: makeGraphNonNull(Args, ['user_id'], 'all'),
  resolve: async (root, { type, user_id, status, purchaser_id }) => {
    let row = {};
    purchaser_id =
      purchaser_id !== undefined && purchaser_id ? purchaser_id : '10124';
    type = type !== undefined && type ? type : '360';
    status = status !== undefined && status ? status : 'unclaimed';
    const ticket = await Ticket.forge({
      user_id,
      purchaser_id,
      type,
      year: process.year,
      status,
    }).save();
    return ticket.attributes;
  },
};
module.exports = {
  Type,
  Update,
  Add,
  Field,
  Fields,
};
