$(document).on('ready page:load', function() {
    $('#calendar').fullCalendar({
        theme: false,
        editable: false,
        events: '/events.json',
        header: {
            left: 'today',
            center: 'prev, title, next',
            right: 'agendaDay, agendaWeek, month'
        },
        defaultView: 'agendaWeek',
        height: getCalHeight(),
        windowResize: function(view) {
            $('#calendar').fullCalendar('option', 'height', getCalHeight());
        },
    });
});

function getCalHeight() {
    return $(window).height() - 120;
}
