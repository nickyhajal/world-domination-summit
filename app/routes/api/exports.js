const x = {
  people: ({ query: { year, type, first_time } }) => ({
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
