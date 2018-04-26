const { GraphQLObjectType, GraphQLSchema } = require('graphql');
const graphqlHTTP = require('express-graphql');
const EventGraph = require('../../graph/events');
const UserGraph = require('../../graph/users');
const Transactions = require('../../graph/transactions');
const Tickets = require('../../graph/tickets');
const Stats = require('../../graph/stats');
const UserNoteGraph = require('../../graph/UserNoteGraph');
const BookingGraph = require('../../graph/bookings');
const PagesGraph = require('../../graph/pages');

const query = new GraphQLObjectType({
  name: 'Query',
  description: 'What a Gem',
  fields: () => ({
    event: EventGraph.Field,
    events: EventGraph.Fields,
    user: UserGraph.Field,
    users: UserGraph.Search,
    stats: Stats.Field,
    booking: BookingGraph.Field,
    bookings: BookingGraph.Fields,
    page: PagesGraph.Field,
    pages: PagesGraph.Fields,
    transaction: Transactions.Field,
    transactions: Transactions.Fields,
    tickets: Tickets.Fields,
  }),
});

const mutation = new GraphQLObjectType({
  name: 'Mutation',
  fields: {
    ticketUpdate: Tickets.Update,
    ticketAdd: Tickets.Add,
    userAdd: UserGraph.Add,
    userUpdate: UserGraph.Update,
    eventAdd: EventGraph.Add,
    eventUpdate: EventGraph.Update,
    userGiveTicket: UserGraph.GiveTicket,
    userNoteAdd: UserNoteGraph.Add,
    pageAdd: PagesGraph.Add,
    pageUpdate: PagesGraph.Update,
    bookingUpdate: BookingGraph.Update,
  },
});

const schema = new GraphQLSchema({
  query,
  mutation,
});

module.exports = graphqlHTTP({
  schema,
  graphiql: true,
});
