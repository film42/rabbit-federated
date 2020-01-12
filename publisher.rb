require "bunny"

cluster = ARGV[0] || "rabbit2"
rabbit_port = `docker-compose port #{cluster} 5672`.strip.split(":").last.to_i

puts "Publishing to: #{cluster}:#{rabbit_port}"

conn = Bunny.new(hosts: ["0.0.0.0"], port: rabbit_port, heartbeat_timeout: 8)
conn.start

ch = conn.create_channel
ex = ch.topic("federated.events", :durable => true)
qu = ch.queue("abacus.abacus.transaction.created", :durable => true)
qu.bind(ex, :routing_key => "abacus.transaction.created")

loop do
  ch.confirm_select
  100.times do
    ex.publish("hello, world", {:routing_key => "abacus.transaction.created"})
  end
  ch.wait_for_confirms

  sleep 0.01
end
