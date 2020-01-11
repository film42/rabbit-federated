#### RabbitMQ Federated Queues Example

I copied a lot of helper code from https://github.com/dantswain/rabbitmq_ha_federation which focuses on federated
exchanges. This focuses on federated queues: load balancing queues across different clusters.

The example builds 3 rabbitmq nodes: rabbit1, rabbit2, and rabbit3.

Running `docker compose up` will start the rabbitmq nodes.

You then need to connect the rabbitmq nodes together using `./federate-queues.sh` which creates a bi-directional link
between the nodes: 1 to 2, 2 to 3, and 3 to 1.

Note: There's a `./federate-exchange.sh` as well, but it's only there for reference.

Now you can begin publishing:

1. The `ruby publish.rb rabbit1` script will publish to a single node over and over.
2. The `ruby publish-switcher.rb` script will publish 10,000 messages in chunks of 100 to random nodes.
3. The `ruby conusmer.rb rabbit1` script will consume from one node and write results to a csv file.
4. The `ruby check-results.rb` script verifies that consumers received all 10k messages from `publish-switcher.rb`.

Opening the rabbitmq admin:

1. `docker-compose port rabbit1 15672`
1. `docker-compose port rabbit2 15672`
1. `docker-compose port rabbit3 15672`

Note: The scripts use this same snippet to auto-connect to the correct rabbit node.

---

MIT License.
