#!/usr/bin/ruby
# Version (0.81)
# Created by Artem Titoulenko (artem.titoulenko@gmail.com)
# clock in application. I'm tired of counting.

# C.rb -- Time keeping script. 
# Call with no params to clock in/out
# Params:
#   ?       : are you clocked in? check. Optional 'color' argument
#   log     : peek at the work log
#   total   : how long have you worked? (hours)
#             optional " at rate <n>" displays billable
#             ex: c total at rate 25 #=> $539.53
#             sum for project at rate n
#   update  : update the app, optional 'force' argument
#   clear   : empties the log file 
# 
# Beta:
#   invoice at rate <n> : Makes a rudementary invoice at rate <n>

require 'open-uri'

clocked_in = false
log = []

#first lets read the status file
path = File.expand_path "~/.clockwork.log", __FILE__

unless File.exists?(path)
  File.new(path, "w")
  puts "Log file created: ~/.clockwork.log"
end

File.open(path,"r") do |file|
  while line = file.gets
    work = line.match(/(.*?) (?=in|out)/)
    log << $1.to_f if work != nil
  end
  clocked_in = log.size % 2 != 0
end 

# sorta beta? I don't know how well this will work but it's interesting
def update_self
    updated_version = open('https://gist.github.com/raw/857843/C.rb').read
    File.open(__FILE__, 'w+') do |f|
      f.puts updated_version
    end
end

def show_log(log)
  k = true
  log.each do |x| 
    puts "#{Time.at(x)} #{k ? "in" : "out"}"
    puts "\n" if !k; k = !k
  end
end

def total(log)
  if log.size == 1
    return ((Time.now - Time.at(log.first)) / 3600).to_decimal_places(3)
  else
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
    
    if log.size % 2 != 0
      worked += Time.now - Time.at(log.last)
    end
    
    return (worked / 3600).to_decimal_places(3).to_f
  end
end

class Float; def to_decimal_places(n); return format("%.#{n}f",self).to_f; end; end

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
  when "clear"
    puts "Are you sure you want to clear the logfile? (y/n): "
    confirm = STDIN.gets.chomp
    if confirm == "y"
      File.open(path,"w") {|f| f.write("")}
      puts "Cleared file! I think..."
    else
      puts "Phew! Didn't think you'd want to do that."
    end
  when "invoice"
    if ARGV[1] == "at" and ARGV[2] == "rate" and ARGV[3] != nil and ARGV[3].to_f >= 0
      nice_rate = ARGV[3].to_f.to_decimal_places(2)
      log << Time.now if log.size % 2 != 0 #we can't just ask for $ when clocked in
      show_log(log)
      puts "-"*40
      puts "#{total(log)} hours * $#{nice_rate}/hr = $#{total(log) * nice_rate}"  
    end
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
    puts "Params:\n"
    puts "\t?       : are you clocked in? check. Optional 'color' argument"
    puts "\tlog     : peek at the work log"
    puts "\ttotal   : how long have you worked? (hours)"
    puts "\t          optional \" at rate <n>\" displays billable"
    puts "\t          ex: c total at rate 25 #=> $539.53"
    puts "\t          sum for project at rate n"
    puts "\tupdate  : update the app, optional 'force' argument"
    puts "\tclear   : empties the log file "
    puts "\nBeta:\n"
    puts "\tinvoice at rate <n> : Makes a rudementary invoice at rate <n>"
  when "?"
    if ARGV[1] == "color"
      puts "#{clocked_in ? "\e[1;32m" : "\e[1;31m"}#{total(log)} hrs\e[0m"
    else
      puts "You #{clocked_in ? "are" : "aren't"} clocked in"
    end
  when "log"
    show_log(log)
  when "total"    
    if ARGV[1] == "at" and ARGV[2] == "rate" and ARGV[3].to_f >= 0 and ARGV[3] != nil
      puts "$#{total(log).to_decimal_places(2) * ARGV[3].to_f}"  
    else
      puts "#{total(log)} hours"
    end
  end
end
