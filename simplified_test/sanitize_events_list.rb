#!/usr/bin/env ruby
# coding: utf-8
#############################################################
#                                                           #
#    renumber event-list while keeping relations            #
#                                                           #
#############################################################

require 'yaml'
require 'date'

# translate = %w(company email_server companies )
debug = false

file = ARGV[0] || 'data.yml'

events = YAML::load_file(file)

File.rename file, file.sub(/(\..+)?$/, '.bak\1') unless debug

$before_after = events.each_with_index.map do |e, i|
  [e['id'], i+1]
end.to_h

def translate tok
  if tok.instance_of?(Fixnum)
    $before_after[tok]
  elsif tok.instance_of? Array
    tok.map {|i| translate i}
  elsif tok.instance_of? Hash
    tok.map {|k,v| [k, translate(v)]}.to_h
  else
    tok
  end
end

long_ago = DateTime.now - events.size

events.each_with_index do |e, i|
  translate e
  e['created_at'] = (long_ago + (i + rand)).to_s
end

puts  YAML::dump(events).gsub(/\n-/, "\n\n-") if debug
File.write file, YAML::dump(events).gsub(/\n-/, "\n\n-") unless debug
