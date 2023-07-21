FROM almalinux:9

RUN yum  -y update && yum -y install ruby git jq ruby-devel make gcc redhat-rpm-config sudo go && yum -y clean all  && rm -rf /var/cache

RUN curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | bash
RUN td-agent-gem install fluent-plugin-filter-list --force

RUN gem install parseconfig
RUN gem install misp
RUN gem install opensearch-ruby

RUN mkdir -p /etc/pdnssoc/
RUN touch /etc/td-agent/misp_domains.txt

RUN mkdir /var/run/td-agent

# Setup cron job
RUN go install github.com/aptible/supercronic@latest

CMD td-agent -d /var/run/td-agent/td-agent.pid && /root/go/bin/supercronic /etc/crontab
