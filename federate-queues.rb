require "json"

def install_federation_plugins(current_node:)
  [
    "docker-compose exec #{current_node} rabbitmq-plugins enable rabbitmq_federation",
    "docker-compose exec #{current_node} rabbitmq-plugins enable rabbitmq_federation_management"
  ]
end

def create_upstream(current_node:, upstream_node:, upstream_name:)
  config = {
    "max-hops" => 1,
    "uri" => ["amqp://guest:guest@#{upstream_node}"]
  }
  "docker-compose exec #{current_node} rabbitmqctl set_parameter federation-upstream #{upstream_name} '#{config.to_json}'"
end

def create_upstream_set(current_node:, current_cluster:, upstream_set:)
  config = upstream_set.map { |upstream| { "upstream" => upstream } }
  "docker-compose exec #{current_node} rabbitmqctl set_parameter federation-upstream-set #{current_cluster}_federators '#{config.to_json}'"
end

def create_federation_policy(current_node:, current_cluster:, pattern:)
  config = {
    "federation-upstream-set" => "#{current_cluster}_federators"
  }
  "docker-compose exec #{current_node} rabbitmqctl set_policy --apply-to queues #{current_cluster}_federators '#{pattern}' '#{config.to_json}'"
end

topology = {
  "rabbit1" => {
    "cluster1" => {
      "link1" => "rabbit2",
      "link2" => "rabbit3",
    }
  },
  "rabbit2" => {
    "cluster2" => {
      "link1" => "rabbit1",
      "link2" => "rabbit3",
    }
  },
  "rabbit3" => {
    "cluster3" => {
      "link1" => "rabbit1",
      "link2" => "rabbit2",
    }
  },
}

cs = []
topology.each do |current_node, cluster_description|
  cs.concat(install_federation_plugins(:current_node => current_node))

  cluster_description.each do |cluster, links_description|
    # 1. Create the federation upstream for each node.
    links_description.each do |link, upstream_node|
      cs << create_upstream(:current_node => current_node,
                            :upstream_node => upstream_node,
                            :upstream_name => "#{cluster}_#{link}")
    end

    # 2. Create a federation upstream set for the new upstreams.
    upstream_set = links_description.keys.map {|link| "#{cluster}_#{link}"}
    cs << create_upstream_set(:current_node => current_node,
                              :current_cluster => cluster,
                              :upstream_set => upstream_set)

    # 3. Create a policy that references the upstream set.
    cs << create_federation_policy(:current_node => current_node,
                                   :current_cluster => cluster,
                                   :pattern => "abacus.*")
  end
end

cs.each do |command|
  puts command
  exit 1 unless system(command)
end
