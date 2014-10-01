class Event < ActiveRecord::Base
    extend SimpleCalendar
    has_calendar
end
