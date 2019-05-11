require_relative 'support/methods'

namespace :flipflop do
  # Encapsulates support methods to prevent name collision with global
  # rake namespace
  m = Object.new
  m.extend Flipflop::Rake::SupportMethods

  desc 'Enables a feature with the specified strategy.'
  task :turn_on, %i[feature strategy] => :environment do |_task, args|
    m.switch_feature! args[:feature], args[:strategy], true
    puts "Feature :#{args[:feature]} enabled!"
  end

  desc 'Disables a feature with the specified strategy.'
  task :turn_off, %i[feature strategy] => :environment do |_task, args|
    m.switch_feature! args[:feature], args[:strategy], false
    puts "Feature :#{args[:feature]} disabled!"
  end

  desc 'Clears a feature with the specified strategy.'
  task :clear, %i[feature strategy] => :environment do |_task, args|
    m.clear_feature! args[:feature], args[:strategy]
    puts "Feature :#{args[:feature]} cleared!"
  end

  desc 'Shows features table'
  task features: :environment do
    puts m.build_features_table
  end
end
