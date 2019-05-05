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

  desc 'Shows features table'
  task features: :environment do
    # Build features table...
    rows = m.features.inject([]) do |array, feature|
      row = [feature.name, feature.description]
      m.strategies.each do |strategy|
        row << m.status_label(strategy.enabled?(feature.key))
      end
      array << row
    end

    table = m.table_class.new headings: m.table_header, rows: rows

    # Print table
    puts table
  end
end
