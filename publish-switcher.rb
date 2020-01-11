require "bunny"

clusters = (ARGV[0] || "rabbit1,rabbit2,rabbit3").split(",")

connections = clusters.map do |cluster|
  rabbit_port = `docker-compose port #{cluster} 5672`.strip.split(":").last.to_i
  conn = Bunny.new(hosts: ["0.0.0.0"], port: rabbit_port, heartbeat_timeout: 8)
  conn.start
  conn
end

channels_with_exchange = connections.map do |conn|
  ch = conn.create_channel
  ex = ch.topic("federated.events", :durable => true)
  qu = ch.queue("abacus.abacus.transaction.created", :durable => true)
  qu.bind(ex, :routing_key => "abacus.transaction.created")

  [ch, ex]
end

i = 0
100.times do
  ch, ex = channels_with_exchange.sample

  ch.confirm_select
  100.times do
    i += 1

    ex.publish("#{i}", {:routing_key => "abacus.transaction.created"})
  end
  ch.wait_for_confirms

  sleep 0.01
end
