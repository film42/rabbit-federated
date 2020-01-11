#!/bin/bash

set -e

docker-compose exec rabbit1 rabbitmq-plugins enable rabbitmq_federation
docker-compose exec rabbit1 rabbitmq-plugins enable rabbitmq_federation_management
docker-compose exec rabbit2 rabbitmq-plugins enable rabbitmq_federation
docker-compose exec rabbit2 rabbitmq-plugins enable rabbitmq_federation_management
docker-compose exec rabbit3 rabbitmq-plugins enable rabbitmq_federation
docker-compose exec rabbit3 rabbitmq-plugins enable rabbitmq_federation_management

federate_nodes() {
  echo "Federating $1 to $2, cluster: $3"
  config="{\"max-hops\": 1, \"uri\": [\"amqp://guest:guest@$2\"]}"
  docker-compose exec $1 rabbitmqctl set_parameter federation-upstream $3 "${config}"
  config="[{\"upstream\": \"$3\"}]"
  docker-compose exec $1 rabbitmqctl set_parameter federation-upstream-set $3_federators "${config}"
  config="{\"federation-upstream-set\": \"$3_federators\"}"
  docker-compose exec $1 rabbitmqctl set_policy --apply-to queues federation_test "abacus.*" "${config}"
}

# 1 to 2
federate_nodes "rabbit1" "rabbit2" "cluster1_link1"
federate_nodes "rabbit2" "rabbit1" "cluster2_link1"

# 2 to 3
federate_nodes "rabbit2" "rabbit3" "cluster2_link2"
federate_nodes "rabbit3" "rabbit2" "cluster3_link1"

# 3 to 1
federate_nodes "rabbit1" "rabbit3" "cluster1_link2"
federate_nodes "rabbit3" "rabbit1" "cluster3_link2"
