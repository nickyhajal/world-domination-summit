const x = {
  people: ({ query: { year, type, first_time, intro } }) => ({
    fields: [
      'first_name',
      'last_name',
      'email',
      'ticket_type',
      'user_name',
      'type as attendee_type',
      'hash as unique_id',
      'pre17',
      'pre18',
      'attending14',
      'attending15',
      'attending16',
      'attending17',
      'attending18',
      'site',
      'twitter',
      'facebook',
      'location',
      'address',
      'address2',
      'city',
      'region as region_state_province',
      'country',
      'zip',
      'calling_code',
      'phone',
      'intro as intro_step',
    ],
    from: 'users as u',
    joins: [],
    orderBy: 'u.created_at',
    wheres: qb => {
      if (year) {
        if (typeof year === 'string') year = year.split(',');
        qb.where(function() {
          year.forEach(y =>
            this.orWhere(`u.attending${y.substr(2, 2)}`, '=', '1')
          );
        });
      }
      if (type) {
        if (typeof type === 'string') type = type.split(',');
        qb.whereIn('type', type);
      }
      if (first_time) {
        let yr = +process.yr - 1;
        let yrs = [];
        while (yr >= 14) {
          yrs.push(yr);
          yr -= 1;
        }
        switch (first_time) {
          case 'no':
            {
              qb.where(function() {
                yrs.forEach(y => this.orWhere(`u.attending${y}`, '=', '1'));
              });
            }
            break;
          case 'yes': {
            qb.where(function() {
              yrs.forEach(y =>
                this.where(function() {
                  this.where(`u.attending${y}`, '!=', '1');
                  this.orWhereNull(`u.attending${y}`);
                })
              );
            });
          }
        }
      }
      if (intro) {
        switch (intro) {
          case 'complete':
            {
              qb.where('intro', '=', '4,0');
            }
            break;
          case 'yes':
            {
              qb.where('intro', '!=', '4,0');
            }
            break;
        }
      }
    },
  }),
  tickets: ({ query: { year, type, status } }) => ({
    fields: [
      't.ticket_id as ticket_id',
      't.status as ticket_status',
      't.type as ticket_type',
      'u.first_name as attendee_first_name',
      'u.last_name as attendee_last_name',
      'u.email as attendee_email',
      'p.first_name as purchaser_first_name',
      'p.last_name as purchaser_last_name',
      'p.email as purchaser_email',
      'u.ticket_type as user_ticket_type',
      'u.type as attendee_type',
      'u.attending18',
      't.created_at as ticket_created',
    ],
    from: 'tickets as t',
    joins: [
      ['users as p', 't.purchaser_id', 'p.user_id'],
      ['users as u', 't.user_id', 'u.user_id'],
    ],
    orderBy: 't.created_at',
    wheres: qb => {
      if (year) {
        if (typeof year === 'string') year = year.split(',');
        qb.whereIn('t.year', year);
      }
      if (type) {
        if (typeof type === 'string') type = type.split(',');
        qb.whereIn('t.type', type);
      }
      if (status) {
        if (typeof status === 'string') status = status.split(',');
        qb.whereIn('t.status', status);
      }
    },
  }),
  events: ({
    query: { year, type, active, rejected, rsvp, available, for_type },
  }) => ({
    fields: [
      'event_id',
      'year',
      'type',
      'for_type',
      'what',
      'num_rsvps',
      'max',
      'num_free',
      'free_max',
      'created_at',
    ],
    from: 'events as e',
    joins: [],
    orderBy: 'created_at',
    wheres: qb => {
      if (year) {
        if (typeof year === 'string')
          year = year.split(',').map(y => y.substr(2, 2));
        qb.whereIn('year', year);
      }
      if (type) {
        if (typeof type === 'string') type = type.split(',');
        qb.whereIn('type', type);
      }
      if (for_type) {
        if (typeof for_type === 'string') for_type = for_type.split(',');
        qb.whereIn('for_type', for_type);
      }
      if (active && active !== 'all') {
        qb.where('active', active === 'yes' ? '1' : '0');
      }
      if (rejected && rejected !== 'all') {
        qb.where('ignored', rejected === 'yes' ? '1' : '0');
      }
      if (rsvp && rsvp !== 'all') {
        qb.where('max', rsvp === 'yes' ? '>' : '=', '0');
      }
      if (available && available !== 'all') {
        qb.whereRaw(`max ${available === 'yes' ? '>' : '<='} num_rsvps`);
      }
    },
  }),
  hotel: args => ({
    fields: [
      'first_name',
      'last_name',
      'email',
      'b.type as booking_type',
      'extra',
    ],
    from: 'bookings as b',
    joins: [['users as u', 'b.user_id', 'u.user_id']],
    orderBy: 'b.created_at',
  }),
  transfers: args => ({
    fields: [
      'f.first_name as from_fname',
      'f.last_name as from_lname',
      'f.email as from_email',
      'to.first_name as to_fname',
      'to.last_name as to_lname',
      'to.email as to_email',
    ],
    from: 'transfers as t',
    joins: [
      ['users as f', 't.user_id', 'f.user_id'],
      ['users as to', 't.to_id', 'to.user_id'],
    ],
    orderBy: args.orderBy ? args.orderBy : 't.created_at',
    wheres: args.wheres
      ? args.wheres
      : [['year', '=', process.year], ['status', '=', 'paid']],
  }),
  rsvps: ({ query: { event_id } }) => ({
    fields: ['u.first_name', 'u.last_name', 'u.email'],
    from: 'event_rsvps as r',
    joins: [['users as u', 'u.user_id', 'r.user_id']],
    orderBy: 'r.stamp',
    wheres: qb => {
      if (event_id) {
        qb.where('r.event_id', '=', event_id);
      }
    },
  }),
};

const csv = rows => {
  // console.log(rows);
  if (rows.length) {
    return `sep=;\n${Object.keys(rows[0])
      .map(h => h.replace(/_/g, ' '))
      .join(';')}\n${rows
      .map(row => {
        return Object.values(row).join(';');
      })
      .join('\n')}`;
  }
  return 'No results';
};

module.exports = async args => {
  let {
    from,
    fields,
    name,
    orderBy,
    sortDir,
    joins,
    wheres,
    format,
  } = Object.assign(
    { orderBy: 'created_at', sortDir: 'DESC', format: 'csv' },
    args,
    x[args.name](args)
  );
  query = process.knex.select(fields).from(from);
  if (joins) {
    joins.forEach(join => {
      query.leftJoin(join[0], join[1], join[2]);
    });
  }
  if (typeof wheres === 'function') {
    wheres(query);
  } else if (wheres) {
    wheres.forEach(w => {
      query.where(w[0], w[1], w[2]);
    });
  }
  query.orderBy(orderBy, sortDir);
  const results = await query;
  return format === 'csv' ? csv(results) : results;
};
