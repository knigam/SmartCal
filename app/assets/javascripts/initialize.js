$(document).on('ready page:load', function() {
    $('#calendar').fullCalendar({
        theme: true,
        editable: true,
        events: '/events.json',
        header: {
            left: 'today',
            center: 'prev, title, next',
            right: 'agendaDay, agendaWeek, month'
        },
        defaultView: 'agendaWeek',
    });
});
