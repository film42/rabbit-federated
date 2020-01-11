clusters = (ARGV[0] || "rabbit1,rabbit2,rabbit3").split(",")
data = clusters.map do |c|
  File.read("#{c}.csv").split("\n").map(&:to_i)
end
data = data.flatten.sort
data_uniq = data.uniq

puts "Has entire series?:"
puts [data_uniq.first, "...", data_uniq.last].inspect
puts data_uniq.uniq == (1..10000).to_a

puts "Printing duplicates:"
puts data.group_by {|k| k}.reject { |k,v| v.size == 1 }.inspect
