module CacasReloader
  def self.load_em
    cacas_dir = Rails.root.join('lib','cacas')
    load cacas_dir.join 'cacas.rb'
    load cacas_dir.join 'adapter_event.rb'
    load cacas_dir.join 'command.rb'
    adapters_dir = Rails.root.join('lib', 'cacas', 'adapters')
    Dir.entries(adapters_dir)
      .select {|d| File.directory? adapters_dir.join d}
      .reject {|d| /^\.{1,2}$/.match d}
      .each {|d| load File.join(adapters_dir, d, "#{d}.rb")}

    Cacas.load_adapters
  end
end
