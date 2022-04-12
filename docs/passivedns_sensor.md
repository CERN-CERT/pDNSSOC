# pDNS sensor

We are currently investigating available open source pDNS sensor solutions to integrate with pDNSSOC. There is a variety of implementations, among them:

* [passivedns](https://github.com/gamelinux/passivedns/)
* [DNSMonster](https://github.com/mosajjal/dnsmonster)
* [gopassivedns](https://github.com/Phillipmartin/gopassivedns) - :warning: Unmaintained :warning:
* [Farsight SIE DNS Sensor](https://github.com/farsightsec/sie-dns-sensor/)
* pDNS(DNS?) data from Bro/Zeek
* DNS logs directly above the recursive (Still not including specific client device information)

## Sensor deployment

```mermaid
flowchart LR;

    subgraph dnsclients [DNS clients]
        Institution_Clients(Clients)
    end

    subgraph dnsservers [DNS Servers]
        DNS_Servers(DNS)
    end

    subgraph upstreamdnsservers [Upstream DNS]
        Upstream_DNS(DNS)
    end


    dnsclients -->dnsservers

    dnsservers --> TAP/SPAN2((tap/span))
    TAP/SPAN2((tap/span)) -->upstreamdnsservers

    pDNS[Sensor] -->|Server2Server,\nabove the recursive| TAP/SPAN2

```

The sensor is installed and operated by the client institute at the resolving servers, collecting only server-to-server traffic between recursive resolvers and authoritative servers:
* No link between people and traffic can be established by [Correlation Engine](./docs/correlation_engine.md).
* Only non-cached traffic is probed by the sensor, significantly reducing the data sent to the [Correlation Engine](./docs/correlation_engine.md).