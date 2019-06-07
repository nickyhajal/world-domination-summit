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
const Transfers = require('../../graph/Transfers');
const Notifications = require('../../graph/Notifications');
const Places = require('../../graph/places');
const RaceTasks = require('../../graph/racetasks');

const query = new GraphQLObjectType({
  name: 'Query',
  description: 'What a Gem',
  fields: () => ({
    event: EventGraph.Field,
    events: EventGraph.Fields,
    user: UserGraph.Field,
    users: UserGraph.Search,
    notification: Notifications.Field,
    notifications: Notifications.Fields,
    stats: Stats.Field,
    booking: BookingGraph.Field,
    bookings: BookingGraph.Fields,
    transfers: Transfers.Fields,
    page: PagesGraph.Field,
    pages: PagesGraph.Fields,
    transaction: Transactions.Field,
    transactions: Transactions.Fields,
    place: Places.Field,
    places: Places.Fields,
    racetask: RaceTasks.Field,
    racetasks: RaceTasks.Fields,
    tickets: Tickets.Fields,
  }),
});

const mutation = new GraphQLObjectType({
  name: 'Mutation',
  fields: {
    notificationAdd: Notifications.Add,
    notificationUpdate: Notifications.Update,
    ticketUpdate: Tickets.Update,
    ticketAdd: Tickets.Add,
    userAdd: UserGraph.Add,
    rsvpAdd: UserGraph.RsvpAdd,
    rsvpDelete: UserGraph.RsvpDelete,
    resendEmail: UserGraph.ResendEmail,
    placeAdd: Places.Add,
    placeUpdate: Places.Update,
    placeDelete: Places.Delete,
    racetaskAdd: RaceTasks.Add,
    racetaskUpdate: RaceTasks.Update,
    racetaskDelete: RaceTasks.Delete,
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
