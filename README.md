<img alt="GitHub contributors" src="https://img.shields.io/github/contributors/CERN-CERT/pDNSSOC"> <img alt="GitHub release (with filter)" src="https://img.shields.io/github/v/release/CERN-CERT/pDNSSOC"><img alt="GitHub Discussions" src="https://img.shields.io/github/discussions/CERN-CERT/pDNSSOC">
<br>
<br>
<p align="center">
  <img src="https://github.com/CERN-CERT/pDNSSOC/assets/1295367/a4173633-820e-4da3-9d81-19f222b67ae3" width="30%" height="30%" />
  <br>For CIRTs with deadlines

</p>






# pDNSSOC

pDNSSOC is a minimalistic toolset allowing DNS data to be centrally collected, and correlated with malicious domains / IPs from a MISP instance.

Basically:
- A collector runs on the DNS servers
- A dedicated pDNSSOC instance collects, correlates and generates alerts.

The goal is to identify signs of infection on the clients making the DNS requests.

A typical use case would be universities deploying a pDNSSOC client on their DNS server, and sending DNS data to a pDNSSOC server operated by a central CSIRT (NREN, campus, etc.).

## Getting started
* [:bookmark_tabs: Installation guide](../../wiki)
* [:beetle: Issue tracker](../../issues)
* [:loudspeaker: Community discussions](../../discussions)
* [:question: Frequently asked questions](./FAQ.md)
* [:bar_chart: Presentations](./docs/presentations.md)

## Acknowledgments
pDNSSOC would not exist without:
* Its contributors and the support from their funding agencies
* [go-dnscollector](https://github.com/dmachard/go-dnscollector)
* [MISP](https://github.com/MISP/MISP/)

## License
Distributed under the MIT License. See [LICENSE.md](./LICENSE.md) for more information.
