require 'icalendar'

cals = Icalendar::Calendar.parse(File.open("ara-schedule.ics"))
cal = cals.first

cal.events.each do |event|
  puts "#{event.summary}"
  puts "\tstart date-time: #{event.dtstart}"
end
