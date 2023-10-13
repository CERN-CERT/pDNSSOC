## FAQ

Q: What happens if a malicious domain is added to MISP _after_ a victim resolved that domain?

_A: The pDNSSOC instance automatically reprocesses all the DNS resolutions on a daily basis. The limit is set by configuration or the disc space available on the pDNSSOC instance._

Q: What can you infer from DNS traffic?

_A: The correlation with MISP events can provide accurate contextual information regarding the nature of the threat, its purpose and other indicators of compromise that can be leveraged to investigate the victim system._

Q: Is it possible to connect pDNSSOC to multiple MISP instances?

_A: Yes, pDNSSOC will combine the intel from several MISP instances and allow for specific follow up in the resulting alerts._

Q: An external team has their own "private" MISP instance and pDNSSOC deployment. How could we benefit from it without breaching TLP or privacy?

_A: pDNSSOC can send incoming DNS data to be reprocessed by another pDNSSOC instance operated by a different team.

**Privacy**: DNS collection can be configured to hide the client IP and use either the DNS server IP or the pDNSSOC instance IP instead. As a result, the client IP or originating DNS server is not exposed to the external team.

**TLP**: The external team can alert the originating pDNSSOC or DNS source without revealing specific data regarding the MISP event._

Q: Are there performance or scalability concerns regarding pDNSSOC?

_A: pDNSSOC deployments follow a scale-out approach. Tests showed that a single Raspberry Pi was sufficient to handle data from dozens health organizations._

Q: Is pDNSSOC aimed at prevention?

_A: No. A primary objective of pDNSSOC is to improve incident response capabilities. With sufficient pDNSSOC coverage, CSIRTs should simply add malicious IPs/Domains in MISP to obtain a near-realtime view of the ongoing attack against their community. Connecting pDNSSOC instances as well as MISP instances together allows a community to response together to security incidents._