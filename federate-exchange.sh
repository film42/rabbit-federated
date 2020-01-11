#!/bin/bash

set -e

docker-compose exec rabbit1 rabbitmq-plugins enable rabbitmq_federation
docker-compose exec rabbit1 rabbitmq-plugins enable rabbitmq_federation_management
docker-compose exec rabbit2 rabbitmq-plugins enable rabbitmq_federation
docker-compose exec rabbit2 rabbitmq-plugins enable rabbitmq_federation_management

# federate 1 to 2
config='{"max-hops": 1, "uri": ["amqp://guest:guest@rabbit2"]}'
docker-compose exec rabbit1 rabbitmqctl set_parameter federation-upstream cluster1 "${config}"
config='[{"upstream": "cluster1"}]'
docker-compose exec rabbit1 rabbitmqctl set_parameter federation-upstream-set cluster1_federators "${config}"
config='{"federation-upstream-set": "cluster1_federators"}'
docker-compose exec rabbit1 rabbitmqctl set_policy --apply-to exchanges federation_test "federated.*" "${config}"
config='{"ha-mode": "all"}'
docker-compose exec rabbit1 rabbitmqctl set_policy ha-federation "^federation:*" "${config}"

# federate 2 to 1
config='{"max-hops": 1, "uri": ["amqp://guest:guest@rabbit1"]}'
docker-compose exec rabbit2 rabbitmqctl set_parameter federation-upstream cluster2 "${config}"
config='[{"upstream": "cluster2"}]'
docker-compose exec rabbit2 rabbitmqctl set_parameter federation-upstream-set cluster2_federators "${config}"
config='{"federation-upstream-set": "cluster2_federators"}'
docker-compose exec rabbit2 rabbitmqctl set_policy --apply-to exchanges federation_test "federated.*" "${config}"
config='{"ha-mode": "all"}'
docker-compose exec rabbit2 rabbitmqctl set_policy ha-federation "^federation:*" "${config}"
