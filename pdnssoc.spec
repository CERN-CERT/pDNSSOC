# pdnssoc.spec
%define rbname pdnssoc
%define version 0.1.3
%define release 1

Name:           pdnssoc
Version:        %{version}
Release:        %{release}
Summary:        pDNSSOC RPM Package
License:        MIT
URL:            https://github.com/CERN-CERT/pDNSSOC
Group:          Applications/System
Packager:       SAFER <admin@safer-trust.org>
BuildRoot:      %{_tmppath}/%{name}-root
Source0:        https://rubygems.org/downloads/pdnssoc-%{version}.gem
Provides:       ruby(Pdnssoc) = %{version}

# Dependencies for the RPM package
Requires:       ruby >= 2.5.0
Requires:       td-agent

# Directiories for gem
%define gemdir /usr/local/share/gems
%define gembuilddir %{buildroot}%{gemdir}
%define gemworkdir %{gembuilddir}/gems/pdnssoc-%{version}

# Directories for pdnssoc
%define pdnssoc_code_root /usr/local/bin/pdnssoc
%define pdnssoc_code %{buildroot}%{pdnssoc_code_root}
%define pdnssoc_config_root /etc/pdnssoc
%define pdnssoc_config %{buildroot}%{pdnssoc_config_root}

# Directories for timers
%define timerdir_root /usr/lib/systemd/system
%define timerdir %{buildroot}%{timerdir_root}

# Other
%define debug_package %{nil}

%description
This package contains the necessary files and configurations for pDNSSOC.

%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires: %{name} = %{version}-%{release}

%description doc
Documentation for %{name}

%prep
%setup -T -c

%build

%install
%{__rm} -rf %{buildroot}
mkdir -p %{gembuilddir}
gem install --install-dir %{gembuilddir} --force pdnssoc

# Install fluentd
td-agent-gem install parseconfig
td-agent-gem install misp
td-agent-gem install fluent-plugin-filter-list --force

# Create pdnssoc directory in the build root
mkdir -p %{pdnssoc_config}
mkdir -p %{pdnssoc_code}
mkdir -p %{timerdir}

# Install the configuration files directly to /etc/pdnssoc/
install -D -m 0644 %{gemworkdir}/config/pdnssoc.conf %{pdnssoc_config}/pdnssoc.conf

# Find and install notification_email.html and td-agent.conf
install -D -m 0644 %{gemworkdir}/config/notification_email.html %{pdnssoc_config}/notification_email.html
install -D -m 0644 -o td-agent -g td-agent %{gemworkdir}/config/td-agent.conf %{pdnssoc_config}/td-agent.conf

# Code
cp -a  %{gemworkdir}/lib/* %{pdnssoc_code}/
chmod 755 %{pdnssoc_code}/lookingback.sh
chmod 755 %{pdnssoc_code}/misp_refresh.sh

# Timers definition
mkdir %{pdnssoc_config}/timers
cp -a  %{gemworkdir}/timers/*.timer %{pdnssoc_config}/timers
cp -a %{gemworkdir}/timers/*.service %{timerdir}/

%files
%defattr(-, root, root)

# Configuration files
%config(noreplace) /etc/pdnssoc/pdnssoc.conf
%config(noreplace) /etc/pdnssoc/td-agent.conf
/etc/pdnssoc/notification_email.html

# pDNSSOC code
%{pdnssoc_code_root}/*

# Timers
%{pdnssoc_config_root}/timers/pdnssoc.timer
%{timerdir_root}/pdnssoc.service
%{pdnssoc_config_root}/timers/lookingback.timer
%{timerdir_root}/lookingback.service
%{pdnssoc_config_root}/timers/misp_refresh.timer
%{timerdir_root}/misp_refresh.service

# GEM files
%{gemdir}/gems/pdnssoc-%{version}/*
%{gemdir}/cache/pdnssoc-%{version}.gem
%{gemdir}/specifications/pdnssoc-%{version}.gemspec

%post
# Symbolic link with the timer so the user can easily change the execution time
ln -sf %{pdnssoc_config_root}/timers/pdnssoc.timer %{timerdir_root}/pdnssoc.timer
ln -sf %{pdnssoc_config_root}/timers/lookingback.timer %{timerdir_root}/lookingback.timer
ln -sf %{pdnssoc_config_root}/timers/misp_refresh.timer %{timerdir_root}/misp_refresh.timer

# Enable the timers
systemctl daemon-reload
systemctl enable pdnssoc.timer lookingback.timer misp_refresh.timer
systemctl start pdnssoc.timer lookingback.timer misp_refresh.timer

# Start Fluentd
systemctl restart td-agent.service

%postun
if [ ! "$1" -ge "1" ] ; then
    rm -rf /etc/pdnssoc/
fi

%clean
%{__rm} -rf %{buildroot}

%changelog
* Mon Aug 07 2023 Pau Cutrina, Romain Wartel, Christos Arvanitis <admin@safer-trust.org> - 1.0-1
- Initial RPM package
