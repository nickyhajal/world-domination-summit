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
    console.log(page, per_page);
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
  ticket_id: { type: new GraphQLNonNull(GraphQLInt) },
  type: { type: GraphQLString },
  user_id: { type: GraphQLInt },
  status: { type: GraphQLString },
};

const Update = {
  type: Type,
  args: Args,
  resolve: async (root, { ticket_id, type, user_id, status }) => {
    let row = {};
    const ticket = await Ticket.forge({ ticket_id }).fetch();
    if (status !== undefined) {
      row = ticket.updateStatus(status);
    }
    return row.attributes;
  },
};
module.exports = {
  Type,
  Update,
  Field,
  Fields,
};
