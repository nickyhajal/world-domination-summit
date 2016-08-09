ap.Views.admin = XView.extend
        initialize: ->
                ap.api 'get me', {}, (rsp) =>
                        ap.api 'get user', {user_name: rsp.me.user_name}, (rsp2) =>
                                @user = new ap.User(rsp2.user)
                                @initRender()

                @pageMap =
                        downloads:
                                title: "Admin Downloads"
                                pages:
                                        [
                                                {page: 'downloads', title: 'Admin Downloads'}
                                        ]
                        speakers:
                                title: "Speaker Management"
                                pages:
                                        [
                                                {page: 'speakers', title: 'Speaker List'}
                                                {page: 'add-speaker', title: 'Add a Speaker'}
                                        ]
                        schedule:
                                title: "Schedule Management"
                                pages:
                                        [
                                                {page: 'academies', title: 'Academies'}
                                                {page: 'add-academy', title: 'Add Academy'}
                                                {page: 'schedule', title: 'WDS Schedule'}
                                                {page: 'add-event', title: 'Add an Event'}
                                                {page: 'event-review', title: 'Event Review'}
                                                {page: 'event-export', title: 'Event Export'}
                                                {page: 'meetups', title: 'Meetups'}
                                                {page: 'meetup-review', title: 'Meetup Review'}
                                        ]
                        race:
                                title: "Unconventional Race"
                                pages:
                                        [
                                                {page: 'racetasks', title: 'Race Tasks'}
                                                {page: 'add-racetask', title: 'Add a Race Task'}
                                        ]
                        ambassadors:
                                title: "Ambassador Administration"
                                pages:
                                        [
                                                {page: 'ambassador-review', title: 'Review Ambassador Submissions'}
                                        ]
                        manifest:
                                title: "Attendee Manifest"
                                pages:
                                        [
                                                {page: 'manifest', title: 'Attendee Manifest'}
                                                {page: 'add-attendee', title: 'Add an Attendee'}
                                                {page: 'transfers', title: 'Transfers'}
                                                {page: 'transactions', title: 'Transactions'}
                                        ]
                        screens:
                                title: "Live LCD Screens"
                                pages:
                                        [
                                                {page: 'screens', title: 'LCD Screen Messages'}
                                        ]

        rendered: ->
                @initCapabilities()

        initCapabilities: ->
                capabilities = Array()

                if @user.get('capabilities')?
                        capabilities = @user.get('capabilities')

                if capabilities.length > 0
                        capabilities.sort()

                        for capability in capabilities
                                if @pageMap[capability]?
                                        new_div = $('#link-stub').clone()
                                        new_div.attr('id', 'capability-' + capability)

                                        capabilityTitle = @pageMap[capability].title

                                        new_div.find('h3').html(capabilityTitle)
                                        a_el = new_div.find('a')
                                        for page in @pageMap[capability]['pages']
                                                a_el.clone().attr('href', '/admin/' + page.page).html(page.title).insertBefore(a_el).toggle().addClass('button')
                                        a_el.remove()
                                        new_div.insertBefore('#link-stub').toggle()

                else
                        $('#link-stub').after("<p>Hey! We love that you're looking around, but we need to keep some things hidden in order to preserve the magic! :)</p>")
