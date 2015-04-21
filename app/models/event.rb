class Event < ActiveRecord::Base
    has_many :invites
    has_many :users, through: :invites

    #Places an event for the first time in a location that it does not cause any conflicts. Returns nil if cannot place without conflict
    def place
        conflicts = users_events.select{|e| e.start_time < self.end_bound && e.end_time > self.start_bound}.sort{|a,b| a.start_time <=> b.start_time}
        conflicts -= [self]
        if conflicts.empty?
            return move(self.start_bound)
        end
        if to_min(conflicts.first.start_time) - to_min(self.start_bound) >= to_min(self.duration)
            return move(self.start_bound)
        end

        (0...conflicts.length).each do |i|
            if i != conflicts.length - 1
                if to_min(conflicts[i+1].start_time) - to_min(conflicts[i].end_time) >= to_min(self.duration)
                    return move(conflicts[i].end_time)
                end
            else
                if to_min(self.end_bound) - to_min(conflicts[i].end_time) >= to_min(self.duration)
                    return move(conflicts[i].end_time)
                end
            end
        end
        return move(self.start_bound)
    end

    # Returns true if there is an unavoidable conflict
    def conflict?
        conflicts = users_events.select{|e| e.start_time < self.end_bound && e.end_time > self.start_bound}.sort{|a,b| a.start_time <=> b.start_time}
        conflicts -= [self]
        if conflicts.empty?
            return false
        else
            return (!self.resolve_conflict)
        end
    end

    # places event in a location that no longer conflicts with other events if possible
    # returns true if conflict was resolved, false if not resolvable
    def resolve_conflict
        conflicts = users_events.select{|e| e.start_time < self.end_bound && e.end_time > self.start_bound}.sort{|a,b| a.start_time <=> b.start_time}
        conflicts -= [self]
        # Sort the list of conflicts to pick the events which are more likely to be able to move without conflict
        sorted_conflicts = conflicts.sort{|a,b| (to_min(b.end_bound) - to_min(b.start_bound) - to_min(b.duration)) <=> (to_min(a.end_bound) - to_min(a.start_bound) - to_min(a.duration))}

        if conflicts.size == 1
            c = conflicts.first
            if c.static?
                return false
            end
            
            # With only one conflict, you don't have to check if moving allows you to place the event
            # Check to see if c can be moved. If it can, set new_time to the time that c can be moved to.
            if new_time = c.move?(self)
                self.move(self.start_bound)
                c.move(new_time)
                self.save
                c.save
                return true
            else
                if c.resolve_conflict
                    self.move(self.start_bound)
                    self.save
                    return true
                end
            end
            return false
        end
        
        sorted_conflicts.each do |c|
            
            # If the conflict is static, no point in even check if moving helps
            if c.static?
                next
            end

            index = conflicts.index(c)
            prev_c = conflicts[index - 1]

            # In case this conflict is the earliest conflict possible
            if index == 0
                if to_min(c.end_time) - to_min(self.start_bound) >= to_min(self.duration)
                    if new_time = c.move?(self)
                        self.move(self.start_bound)
                        c.move(new_time)
                        self.save
                        c.save
                        return true
                    else
                        if c.resolve_conflict
                            self.move(self.start_bound)
                            self.save
                            return true
                        end
                    end
                end
            elsif index == conflicts.size - 1
                if to_min(self.end_bound) - to_min(prev_c.end_time) >= to_min(self.duration)
                    if new_time = c.move?(self)
                        self.move(prev_c.end_time)
                        c.move(new_time)
                        self.save
                        c.save
                        return true
                    else
                        if c.resolve_conflict
                            self.move(self.start_bound)
                            self.save
                            return true
                        end
                    end
                end
            # Check to see if moving c would allow us to place the event
            elsif to_min(c.end_time) - to_min(prev_c.end_time) >= to_min(self.duration)
                # This means we can put the event here
                # Check to see if c can be moved. If it can, set new_time to the time that c can be moved to.
                if new_time = c.move?(self)
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

    # Checks to see if its possible to move to another location without collisions assuming addition of event e
    def move?(e)
        return false if self.static?
        conflicts = users_events.select{|e| e.start_time < self.end_bound && e.end_time > self.start_bound}.sort{|a,b| a.start_time <=> b.start_time}

        if !conflicts.include?(e)
            conflicts << e
            conflicts = conflicts.sort{|a,b| a.start_time <=> b.start_time}
        end
        
        conflicts -= [self]
        if to_min(self.start_bound) - to_min(conflicts.first.start_time) >= to_min(self.duration)
            return self.start_bound
        end

        (0...conflicts.length).each do |i|
            if i != conflicts.length - 1
                if to_min(conflicts[i+1].start_time) - to_min(conflicts[i].end_time) >= to_min(self.duration)
                    return conflicts[i].end_time
                end
            else
                if to_min(self.end_bound) - to_min(conflicts[i].end_time) >= to_min(self.duration)
                    return conflicts[i].end_time
                end
            end
        end

        return false
    end

    # move event to a certain start time
    def move(start)
        self.start_time = start
        new_min = start.min + self.duration.min
        new_hour = start.hour + self.duration.hour
        add_day = 0
        if new_min >= 60
            new_hour += new_min/60
            new_min -= (new_min/60) * 60
        end
        if new_hour >= 24
            add_day = 1
            new_hour -= (new_hour/24) * 24
        end
        self.end_time = start.change(day: self.start_time.day + add_day, hour: new_hour, min: new_min)
        return self
    end

    # returns true if static false if dynamic
    def static?
        return (self.end_bound - self.start_bound == self.duration)
    end

    # Converts a time or a date time to minutes
    def to_min(time)
        min = 0
        min += time.hour * 60
        min += time.min
        return min
    end

    def users_events
        return self.users.map{|u| u.events}.flatten
    end
end
