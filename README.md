# pDNSSOC

*Leveraging MISP indicators via a pDNS-based infrastructure as a poor man’s SOC.*

# Introduction

The pDNSSOC project is aimed at organisations, e-infrastructures and federations, interested in leveraging threat intelligence to prevent, detect or investigate malicious connections.
It focuses on providing a minimalistic design and modular deployment.
It correlates Passive DNS (pDNS) data with network-based indicators provided by a connected [MISP](https://www.misp-project.org) instance.

A key goal of pDNSSOC is to allow easy adoption by all service providers, regardless of their maturity level and security effort available.

# Service components

## 1. pDNS sensor

This element provides passiveDNS data to the [Correlation Engine](./docs/correlation_engine.md). It is deployed either directly on a DNS server or on a network link. In the context of pDNSSOC, service providers will be called to deploy this sensor in their infrastracture.

pDNS sensor details and investigation can be found [here](./docs/passivedns_sensor.md).


## 2. Correlation Engine

The [Correlation Engine](./docs/correlation_engine.md) is the main software component of the pDNSSOC architecture.
Its design is simple.

Inputs:
*  **pDNS data**
*  **Network-based indicators** from a connected MISP instance

Outputs:
* **Alerts** sent to pre-defined recipient(s) (supported formats: JSON, email)
* **pDNS data** forwarded to other projects relying on pDNS analysis (Opt-in). 

Multiple [Correlation Engines](./docs/correlation_engine.md). may be deployed to cover many pDNS sources (scale-out model).
The [Correlation Engine](./docs/correlation_engine.md) is aimed at being standalone and easily deployable.

## 3. Alerts management

This component represents a human layer receiving the alerts from the Correlation Engine.
The intent is to provide the analyst(s) with as much contextual information possible to allow them to follow up as appropriate with the originating pDNS source.

Alerts may be sent to a simple email address or ingested by a complex SIEM, based on the chosen deployment model.
Different [Correlation Engines](./docs/correlation_engine.md) can send alerts to the same recipients.

# Deployment options

![Image of deployment models](./images/deployment_model.png)

# References

* https://securityintelligence.com/how-to-use-passive-dns-to-inform-your-incident-response/

* https://www.covert.io/research-papers/security/Exposure%20-%20Finding%20malicious%20domains%20using%20passive%20dns%20analysis.pdf
