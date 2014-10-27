class Event < ActiveRecord::Base

    def check_conflict
        conflicts = Event.where("start_time < ? AND end_time > ?", self.end_time, self.start_time).order("end_time ASC")
        last = conflicts.last
        if last
            buffer = (last.end_time - self.start_time).abs + 600
            self.start_time += buffer
            self.end_time += buffer
            self.check_conflict
        end
    end
end
