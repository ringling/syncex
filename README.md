# Syncex

Synchronization of Lokalebasen lease and sales applications into CouchDb and ElasticSearch
Synchronizations will be triggered directly or via CouchDB _changes streams

## Requirements

### Environment variables

```
COUCH_SERVER_URL=http://sofa.lokalebasen.dk:5984
COUCH_USER=...
COUCH_PASS=...
COUCH_EVENTS=events
COUCH_LOCATION_DB=locations
DK_URL=http://www.lokalebasen.dk
SE_URL=http://www.lokalbasen.se
LB_INTERNAL_API_URL=api/internal/locations
LB_INTERNAL_API_KEY=...
LOCATION_TYPES=lease,user,investment
ERRBIT_API_KEY=...
DEADMANS_SNITCH_URL=...

```

### CouchDB

#### Databases

The following databases are required

**Locations databases***

<TYPE>_locations

Combination of COUCH_LOCATION_DB and LOCATION_TYPES
e.g. lease_locations, user_locations, investment_locations etc.

**Events database

events -> (ENV: COUCH_EVENTS)

Location updates are written to the *<TYPE>_locations* databases

Syncex listens for updates(_changes) on the *events* database

#### Views



**Max sequence number**

All location databases(see above), should contain the view below

```
{
   "_id": "_design/lists",
   "language": "javascript",
   "views": {
       "max_seq_number": {
           "map": "function(doc) {\n  emit(null, doc.metadata.seq_number);\n}",
           "reduce": "_stats"
       }
   }
}
```
