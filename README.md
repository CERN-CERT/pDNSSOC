# pDNSSOC

*Leveraging MISP indicators via a pDNS-based infrastructure as a poor man’s SOC.*

# Introduction

The pDNSSOC project is aimed at organisations, e-infrastructures and federations, interested in leveraging threat intelligence to prevent, detect or investigate malicious connections.
It focuses on providing a minimalistic design and modular deployment.
It correlates Passive DNS (pDNS) data with network-based indicators provided by a connected [MISP](https://www.misp-project.org) instance.

A key goal of pDNSSOC is to allow easy adoption by all service providers, regardless of their maturity level and security effort available.

# Service components

```mermaid
%%{init: {'securityLevel': 'loose', 'useMaxWidth': 'true'}}%%

flowchart LR;
    Log_Collector(Log Collection)

    subgraph dnsservers [DNS Server]
        DNS_Server(DNS)
    end

    subgraph upstreamdnsservers [Upstream DNS]
        Upstream_DNS(DNS)
    end

    subgraph correlationengine [Correlation Engine]
        Log_Ingestion(Log Ingestion)
    end

    dnsclients(DNS Clients)

    alerts(Alerting)

    %%Edge
    MISP --> correlationengine
    correlationengine -->alerts
    Log_Collector ----logformat(Log Format)---> correlationengine
    Log_Collector --> logtype
    dnsclients -->dnsservers
    dnsservers ---logtype(Resolver Response)--> upstreamdnsservers


style Log_Collector stroke:#333,fill:grey,color:white,stroke-width:4px
style Log_Ingestion stroke:#333,fill:grey,color:white,stroke-width:4px
style alerts stroke:#333,fill:grey,color:white,stroke-width:4px
style logformat fill:grey,color:white,stroke:#333,stroke-width:4px,stroke-dasharray: 5 5

click Log_Collector "https://github.com/CERN-CERT/pDNSSOC/blob/main/docs/log_collection.md"
click logformat "https://github.com/CERN-CERT/pDNSSOC/blob/main/docs/log_format.md"
click MISP "https://www.misp-project.org/"
click Log_Ingestion "https://github.com/CERN-CERT/pDNSSOC/blob/main/docs/correlation_engine.md"

```

pDNSSOC is divided in the following discrete parts (grey filled nodes):
1. Log collection
2. Correlation with threat intelligence
3. Alerting

## 1. Log Collection

This element provides DNS data to the [Correlation Engine](./docs/correlation_engine.md). There is a plethora of passive DNS probes and DNS log collectors available with various collection approaches and output formats. In order to support as many deployment scenarios as possible, we have to agree on a [Common Log Format](./docs/log_format.md).

## 2. Correlation Engine

The [Correlation Engine](./docs/correlation_engine.md) is the main software component of the pDNSSOC architecture.
Its design is simple.

Inputs:
*  **DNS logs**
*  **Network-based indicators** from a connected MISP instance

Outputs:
* **Alerts** sent to pre-defined recipient(s) (supported formats: JSON, email)
* **pDNS data** forwarded to other projects relying on pDNS analysis (Opt-in).

Multiple [Correlation Engines](./docs/correlation_engine.md). may be deployed to cover many pDNS sources (scale-out model).
The [Correlation Engine](./docs/correlation_engine.md) is aimed at being standalone and easily deployable.

## 3. Alerting

This component represents a human layer receiving the alerts from the Correlation Engine.
The intent is to provide the analyst(s) with as much contextual information possible to allow them to follow up as appropriate with the originating pDNS source.

Alerts may be sent to a simple email address or ingested by a complex SIEM, based on the chosen deployment model.
Different [Correlation Engines](./docs/correlation_engine.md) can send alerts to the same recipients.

# Deployment options

![Image of deployment models](./images/deployment_model.png)

# References

* https://securityintelligence.com/how-to-use-passive-dns-to-inform-your-incident-response/

* https://www.covert.io/research-papers/security/Exposure%20-%20Finding%20malicious%20domains%20using%20passive%20dns%20analysis.pdf
