# Correlation Engine

:warning: :construction: WORK IN PROGRESS :construction: :warning:

## Contents

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Correlation Engine](#correlation-engine)
  - [Contents](#contents)
  - [Building blocks](#building-blocks)
  - [Areas of work - `WIP`](#areas-of-work-wip)
  - [Timeline - `WIP`](#timeline-wip)

<!-- /code_chunk_output -->


## Building blocks

```mermaid
flowchart LR;

  subgraph Correlation engine
    Ingest((Ingest))
    Storage(Storage)
    Memcached(Memcached)
    Correlate((Correlate))    
  end

  subgraph participants [Participating Institutions]
    pDNSSensor1(pDNS sensor)
    pDNSSensor2(pDNS sensor)
    pDNSSensor3(pDNS sensor)
  end

  subgraph Intelligence
    MISP(MISP) 
  end

  subgraph Alerting
    AlertStorage(Alert Storage)
    Alert((Alert))
  end

pDNSSensor1(pDNS sensor)-->Ingest((Ingest));
pDNSSensor2(pDNS sensor)-->Ingest((Ingest));
pDNSSensor3(pDNS sensor)-->Ingest((Ingest));

MISP(MISP) --> Memcached(Memcached)


Ingest((Ingest)) --> Storage(Storage) 
Storage(Storage) --> Correlate((Correlate))
Memcached(Memcached) --> Correlate((Correlate))
Correlate((Correlate)) --> AlertStorage(Alert Storage)
AlertStorage(Alert Storage) --> Alert((Alert))


Alert((Alert)) --> participants
```

* `MISP` Caching implementation

    Attributes are fetched from one or multiple MISP instances and stored in a KV store solution (`Memcached` at the moment) so as to be ready for correlation without putting pressure on the MISP instances

* Storage solution

    DNS data is ingested from passive DNS sensors. This is where the relarion between originating DNS recursive client and participating institution entity is stored so that alerting is possible.

## Areas of work - `WIP`

- [ ] Storage selection
- [ ] Define whether correlation will also be done for past attributes/DNS logs
- [ ] Define time window for valid MISP attributes
- [ ] Define types of MISP attributes
- [ ] Define different types of DNS logs (DNS Ttraffic above the recursive, passive DNS aggregated logs)
- [ ] Define data flow for pDNS data and Incident response related data


## Timeline - `WIP`

TBD
