class Event < ActiveRecord::Base
    belongs_to :user

    #Places an event for the first time in a location that it does not cause any conflicts. Returns nil if cannot place without conflict
    def place
        move(self.start_bound)
        conflicts = Event.where("start_time < ? AND end_time > ?", self.end_bound, self.start_bound).order("start_time ASC")
        if conflicts.empty? || conflicts.include?(self)
            return true
        end
        if conflicts.first.start_time.to_i - self.start_bound.to_i >= self.duration.to_i
            return move(self.start_bound)
        end

        (0...conflicts.length).each do |i|
            if i != conflicts.length - 1
                if conflicts[i+1].start_time.to_i - conflicts[i].end_time.to_i >= self.duration.to_i
                    return move(conflicts[i].end_time)
                end
            else
                if self.end_bound.to_i - conflicts[i].end_time.to_i >= self.duration.to_i
                    return move(conflicts[i].end_time)
                end
            end
        end
        return move(self.start_bound)
    end

    # Returns true if there is an unavoidable conflict
    def conflict?
        conflicts = Event.where("start_time < ? AND end_time > ?", self.end_time, self.start_time).order("end_time ASC")
        if conflicts.size == 1 && conflicts.include?(self)
            return false
        elsif conflicts
            return (!self.resolve_conflict)
        else
            return true
        end
    end

    # places event in a location that no longer conflicts with other events if possible
    # returns true if conflict was resolved, false if not resolvable
    def resolve_conflict
        conflicts = Event.where("start_time < ? AND end_time > ?", self.end_bound, self.start_bound).order("start_time ASC")
        
        # Sort the list of conflicts to pick the events which are more likely to be able to move without conflict
        sorted_conflicts = conflicts.sort{|a,b| (b.end_bound.to_i - b.start_bound.to_i - b.duration.to_i) <=> (a.end_bound.to_i - a.start_bound.to_i - a.duration.to_i)}
        sorted_conflicts.each do |c|
            
            # If the conflict is static, no point in even check if moving helps
            if c.static?
                next
            end

            index = conflicts.index(c)
            prev_c = conflicts[index - 1]
            
            # Check to see if moving c would allow us to place the event
            if c.end_time.to_i - prev_c.end_time.to_i >= self.duration.to_i
                # This means we can put the event here
                # Check to see if c can be moved. If it can, set new_time to the time that c can be moved to.
                if new_time = c.move?
                    self.move(prev_c.end_time)
                    c.move(new_time)
                    self.save
                    c.save
                    return true
                else
                    if c.resolve_conflict
                        self.move(prev_c.end_time)
                        self.save
                        return true
                    end
                end
            end
        end

        # If we reach here, it is impossible to move the event to a location without conflict
        return false
    end

    # Checks to see if its possible to move to another location without collisions
    def move?
        return false if self.static?
        conflicts = Event.where("start_time < ? AND end_time > ?", self.end_bound, self.start_bound).order("start_time ASC")
        if self.start_bound.to_i - conflicts.first.start_time.to_i >= self.duration.to_i
            return start_bound
        end

        (0...conflicts.length).each do |i|
            if i != conflicts.length - 1
                if conflicts[i+1].start_time.to_i - conflicts[i].end_time.to_i >= self.duration.to_i
                    return conflicts[i].end_time
                end
            else
                if self.end_bound.to_i - conflicts[i].end_time.to_i >= self.duration.to_i
                    return conflicts[i].end_time
                end
            end
        end

        return false
    end

    # move event to a certain start time
    def move(start)
        self.start_time = start
        self.end_time = start.change(hour: start.hour + self.duration.hour, min: start.min + self.duration.min)
        return self
    end

    # returns true if static false if dynamic
    def static?
        return (self.end_bound - self.start_bound == self.duration)
    end
end
