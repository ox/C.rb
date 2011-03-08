#!/usr/bin/ruby
# Version (0.70)
# Created by Artem Titoulenko (artem.titoulenko@gmail.com)
# clock in application. I'm tired of counting.

# C.rb -- Time keeping script. 
# Call with no params to clock in/out
# Params:
#   ?           : are you clocked in? check
#   log         : peek at the work log
#   total       : how long have you worked? (hours)
#   update      : update the app, optional 'force' argument
#   at rate <n> : calculate money earned at a given rate so far
# 
# Beta:
#   invoice at rate <n> : Makes a rudementary invoice

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
  when "invoice"
    if ARGV[1] == "at" and ARGV[2] == "rate" and ARGV[3] != nil and ARGV[3].to_f >= 0
      nice_rate = ARGV[3].to_f.to_decimal_places(2)
      log << Time.now if log.size % 2 != 0 #we can't just ask for $ when clocked in
      show_log(log)
      puts "-"*40
      puts "#{total(log)} hours * $#{nice_rate}/hr = $#{total(log) * nice_rate}"  
    end    
  when "at"
    if ARGV[1] == "rate" and ARGV[2] != nil and ARGV[2].to_f >= 0
      puts "$#{total(log) * ARGV[2].to_f}"  
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
    puts "\t?           : are you clocked in? check"
    puts "\tlog         : peek at the work log"
    puts "\ttotal       : how long have you worked? (hours)"
    puts "\tupdate      : update the app, optional 'force' argument"
    puts "\tat rate <n> : calculate money earned at a given rate so far"
    puts "\nBeta:\n"
    puts "\tinvoice at rate <n> : Makes a rudementary invoice"
  when "?"
    puts "You #{clocked_in ? "are" : "aren't"} clocked in"
  when "log"
    puts show_log(log)
  when "total"    
    puts "#{total(log)} hours"
  end
end