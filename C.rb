#!/usr/bin/ruby
# Version (0.41)
# Created by Artem Titoulenko (artem.titoulenko@gmail.com)
# clock in application. I'm tired of counting.

# C.rb -- Time keeping script. 
# Call with no params to clock in/out
# Params:
#   ?      : are you clocked in? check
#   log    : peek at the work log
#   total  : how long have you worked? (hours)
#   update : update the app, optional 'force' argument

require 'open-uri'

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

# sorta beta? I don't know how well this will work but it's
# interesting
def update_self
    updated_version = open('https://gist.github.com/raw/857843/C.rb').read
    File.open(__FILE__, 'w+') do |f|
      f.puts updated_version
    end
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
  when "version"
    puts (File.read(__FILE__)).match(/# Version \((.*?)\)/)[1].to_f
  when "update"
    k = open('https://gist.github.com/857843').read
    available_version = k.match(/# Version \((.*?)\)/)[1].to_f
    current_version = (File.read(__FILE__)).match(/# Version \((.*?)\)/)[1].to_f
    if available_version > current_version
      puts "version #{available_version} available, updating" 
      update_self
    else
      if !ARGV.empty? and ARGV[1] == "force"
        update_self
      else
        puts "no need to update, you can still use 'update force'"
      end
    end
  when "help"
    puts "C.rb -- Time keeping script. \nCall with no params to clock in/out" 
    puts "Params:\n\t?      : are you clocked in? check\n\tlog    : peek at the work log"
    puts "\ttotal  : how long have you worked? (hours)"
    puts "\tupdate : update the app, optional 'force' argument"
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