#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'open3'

todo_dir = 'ansible-jobfiles/todo'
done_dir = 'ansible-jobfiles/done'

['ansible-jobfiles', todo_dir, done_dir].each {|d| Dir.mkdir d unless File.exists? d}

templ = YAML::load_file 'job.yml'

now = Time::now()
timestamp = now.strftime "%Y-%m-%d_%H:%M:%S-#{now.nsec.to_s 36}"

{"inventory" => "#{timestamp}.inventory",
 "playbook" => "#{timestamp}.yml"}.each do |key, filename|

  f_cont = templ[key].class == String ? templ[key] : templ[key].to_yaml

  open(File.join(todo_dir,filename), 'w') do |fh|

    fh.write f_cont
  end
end

playbook_ids = Dir.entries(todo_dir).select {|f| /\.yml$/ =~ f}.map {|f| f.sub /\.yml$/, ''}

playbook_ids.sort.each do |pb_id|

  # out, err, ps = Open3::capture3 "ansible-playbook", "-i", File.join(todo_dir,"#{pb_id}.inventory"),
  #                                File.join(todo_dir,"#{pb_id}.yml")
  out, err, ps = Open3::capture3 "ansible-playbook", "-i", ",",
                                 File.join(todo_dir,"#{pb_id}.yml")

  %w(.yml .inventory).each do |ext|
    File.rename File.join(todo_dir, "#{pb_id}#{ext}"), File.join(done_dir, "#{pb_id}#{ext}")
  end
end
