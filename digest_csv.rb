#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'csv'

DigestCsv = Struct.new(:csv) do

  attr_accessor :chore_classes

  def data
    CSV.read(csv)
  end

  def task_array
    data.map.with_index do |row, i|
      if (i == 0  || row.uniq == [nil])
        nil
      else
        Task.new(row)
      end
    end.compact
  end

  def tasks_by_desc_value
    task_array.sort_by {|task| task.value}.reverse
  end


  def chore_archetype_list
    @_chore_archetype_list ||= ChoreArchetypeList.new(tasks_by_desc_value)
  end

  def assemble_list
    chore_archetype_list.assemble
  end

  def perform
    assemble_list
    chore_archetype_list.all.each {|list| list.display}
  end
end

Task = Struct.new(:row) do
  def title
    row[0]
  end

  def duration
    row[1]
  end

  def frequency
    row[2]
  end

  def description
    row[3]
  end

  def duration_in_hours
    duration.split.first.to_f
  end

  def frequency_in_days
    frequency.split.first.to_i
  end

  def value
    ((duration_in_hours / frequency_in_days) * 1000).ceil
  end

end

class ChoreArchetypeList
  attr_accessor :first, :second, :third, :fourth, :tasks

  def initialize(tasks)
    @tasks = tasks
    @first = ChoreArchetype.new
    @second = ChoreArchetype.new
    @third = ChoreArchetype.new
    @fourth = ChoreArchetype.new
  end

  def all
    [first, second, third, fourth]
  end

  def lowest
    all.sort_by{|archetype| archetype.current_value}.first
  end

  def assemble
    tasks.each do |task|
      lowest.tasks << task
    end
    all
  end

end

class ChoreArchetype
  attr_accessor :tasks
  def initialize
    @tasks = []
  end

  def current_value
    return 0 if tasks.empty?
    tasks.map{|task| task.value}.inject(:+)
  end

  def display
    puts "====================================================================================="
    puts "YOU ARE THE LORD GOD OF #{tasks.sample.title}"
    puts "YOUR CHORES ARE:"
    tasks.each do |task|
      puts "#{task.title}, which takes #{task.duration} and should be done every #{task.frequency}"
    end
    puts "====================================================================================="
    puts ""
  end
end

csv = DigestCsv.new ARGV[0]
csv.perform
