require "bunny"
require "csv"

cluster = ARGV[0] || "rabbit2"
rabbit_port = `docker-compose port #{cluster} 5672`.strip.split(":").last.to_i

conn = Bunny.new(hosts: ["0.0.0.0"], port: rabbit_port, heartbeat_timeout: 8)
conn.start

ch = conn.create_channel
ex = ch.topic("federated.events", :durable => true)
qu = ch.queue("abacus.abacus.transaction.created", :durable => true)
qu.bind(ex, :routing_key => "abacus.transaction.created")

csv = CSV.open("#{cluster}.csv", "a")
begin
  ch.prefetch(100)
  qu.subscribe(:manual_ack => true) do |delivery_info, metadata, payload|
    begin
      # puts "Consumed #{payload}, #{metadata}, #{delivery_info}"
      print "."
      # Create delay for a random DB query
      sleep 0.001
    ensure
      csv << [payload]
      ch.acknowledge(delivery_info.delivery_tag, false)
    end
  end

  loop { sleep 1 }
ensure
  puts
  puts "Stopping."
  csv.close
end
