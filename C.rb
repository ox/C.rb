#!/usr/bin/ruby
# Version 0.3
# Created by Artem Titoulenko (artem.titoulenko@gmail.com)
# clock in application. I'm tired of counting.

# C.rb -- Time keeping script. 
# Call with no params to clock in/out
# Params:
#   ?     : are you clocked in? check
#   log   : peek at the work log
#   total : how long have you worked? (hours)


clocked_in = false
log = []

#first lets read the status file
path = File.expand_path "~/.clockwork.log", __FILE__

File.open(path,"r") do |file|
  while line = file.gets
    work = line.match(/(.*?) (?=in|out)/)
    log << $1.to_f if work != nil
  end
  clocked_in = log.size % 2 != 0
end 

if ARGV.empty?
  if clocked_in
    File.open(path,"a+") { |f| f.write("#{Time.now.to_f} out\n")}
    puts "Clocking Out"
  else
    File.open(path,"a+") { |f| f.write("#{Time.now.to_f} in\n")}
    puts "Clocking In"
  end
else
  case ARGV.first
  when "help"
    puts "C.rb -- Time keeping script. \nCall with no params to clock in/out" 
    puts "Params:\n\t?     : are you clocked in? check\n\tlog   : peek at the work log"
    puts "\ttotal : how long have you worked? (hours)"
  when "?"
    puts "You #{clocked_in ? "are" : "aren't"} clocked in"
  when "log"
    k = true
    log.each do |x| 
      puts "#{Time.at(x)} #{k ? "in" : "out"}"
      puts "\n" if !k; k = !k
    end
  when "total"
    prev = 0
    worked = 0
    second = false
    log.each do |work|
      if second
        worked += Time.at(work) - Time.at(prev)
      else
        prev = work
      end
      second = !second
    end
    
    if log.size == 1
      puts "#{(Time.now - Time.at(log.first)) / 3600} hours"
    else
      puts "#{worked / 3600} hours"
    end
  end
end