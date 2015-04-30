# Syncex

Synchronization of Lokalebasen lease and sales applications into CouchDb and ElasticSearch
Synchronizations will be triggered directly or via RabbitMQ messages




## HealthCheck

Call these processes, to perform a health and status check

`iex --name syncex@192.168.1.152 --cookie monster -S mix`

```elixir
iex --name syncex_client@192.168.1.152 --cookie monster
Node.ping(:"syncex@192.168.1.152")

# Latest synced event
GenServer.call({:global, Syncex.Status}, {:latest_synced_event, Syncex.UpdateWorker})

# Check if in sync ?
service = %{sequence_server: Syncex.Sequence.Server, location_service: LocationService}
GenServer.call({:global, Syncex.Status}, {:in_sync?, service})
```


Starting Syncex with env set to :test, will disable calls to the handler but changes will still be received

```elixir
SENTRY_DSN=https://user:pass@sentry.services.lokalebasen.dk/16 MIX_ENV=test iex --name syncex@192.168.1.152 --cookie monster -S mix
```


```elixir
Syncex.Status.in_sync?

LocationService.max_sequence_number

Syncex.Sequence.Server.get_sequence

Node.connect(:"syncex@192.168.1.152")

```

## Test
Run tests with `mix test --no-start`, to avoid starting the application

## Requirements

### Environment variables

```shell
SENTRY_DSN="https://user:pass@sentry.services.lokalebasen.dk/16"
COUCH_SERVER_URL=https://couch.lokalebasen.dk
COUCH_USER=...
COUCH_PASS=...
COUCH_LOCATION_DB=locations
LB_INTERNAL_API_KEY=...
ERRBIT_API_KEY=...
DEADMANS_SNITCH_URL=...
RABBITMQ_URL=...
RABBITMQ_EXCHANGE=lb
RABBITMQ_QUEUE=syncex
RABBITMQ_LOCATIONS_ROUTING_KEY=*.location.*
```

### CouchDB

#### Databases

The following databases are required

**Locations databases***

<TYPE>_locations

Combination of COUCH_LOCATION_DB and LOCATION_TYPES
e.g. lease_locations, user_locations, investment_locations etc.
