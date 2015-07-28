cacas_dir = Rails.root.join('lib')
load cacas_dir.join 'cacas.rb'
load cacas_dir.join 'cacas_adapter.rb'
adapters_dir = Rails.root.join('lib', 'cacas', 'adapters')
ADAPTER_MODS = Dir.entries(adapters_dir)
               .select {|d| File.directory? adapters_dir.join d}
               .reject {|d| /^\.{1,2}$/.match d}
               .map {|d|  load File.join(adapters_dir, d, "#{d}_adapter.rb")}

Cacas.load_adapters
