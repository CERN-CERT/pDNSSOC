%global gem_name pdnssoc

Name: rubygem-%{gem_name}
Version: 0.1.4
Release: 1%{?dist}
Summary: pDNS correlation with MISP
License: MIT
URL: https://github.com/CERN-CERT/pDNSSOC/
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
BuildRequires: ruby(release)
BuildRequires: rubygems-devel
BuildRequires: ruby >= 2.5.0
BuildRequires: td-agent
BuildRequires: systemd-rpm-macros
BuildArch: noarch

%description
pDNS correlation with MISP.


%package doc
Summary: Documentation for %{name}
Requires: %{name} = %{version}-%{release}
BuildArch: noarch

%description doc
Documentation for %{name}.

%prep
%setup -q -n %{gem_name}-%{version}

%build
# Create the gem as gem install only works on a gem file
gem build ../%{gem_name}-%{version}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
        %{buildroot}%{gem_dir}/

# Install fluentd gems
td-agent-gem install parseconfig
td-agent-gem install misp
td-agent-gem install fluent-plugin-filter-list --force

# Installing files in /etc/pdnssoc
install -d %{buildroot}%{_sysconfdir}
install -d %{buildroot}%{_sysconfdir}/pdnssoc
touch  %{buildroot}%{_sysconfdir}/pdnssoc/misp_ips.txt
touch  %{buildroot}%{_sysconfdir}/pdnssoc/misp_domains.txt
install -p -m0644 config/pdnssoc.conf %{buildroot}%{_sysconfdir}/pdnssoc/pdnssoc.conf
install -p -m0644 config/td-agent.conf.template %{buildroot}%{_sysconfdir}/pdnssoc/td-agent.conf.template
install -p -m0644 config/notification_email.html %{buildroot}%{_sysconfdir}/pdnssoc/notification_email.html

# Install pdnssoc code
mkdir -p %{buildroot}/usr/local/bin/pdnssoc
cp -a  lib/* %{buildroot}/usr/local/bin/pdnssoc

# Installing timers
install -d %{buildroot}%{_unitdir}
install -p -m0644 timers/* %{buildroot}%{_unitdir}/

%check
pushd .%{gem_instdir}
# Run the test suite.
popd

%files
%dir %{gem_instdir}
%{gem_libdir}
%{gem_instdir}/config
%{gem_instdir}/timers
%{gem_instdir}/lib
%exclude %{gem_cache}
%{gem_spec}
# Timers
%{_unitdir}/pdnssoc.timer
%{_unitdir}/pdnssoc.service
%{_unitdir}/lookingback.timer
%{_unitdir}/lookingback.service
%{_unitdir}/misp_refresh.service
%{_unitdir}/misp_refresh.timer
# Main pdnssoc directory
%dir %{_sysconfdir}/pdnssoc
%config(noreplace) %{_sysconfdir}/pdnssoc/misp_ips.txt
%config(noreplace) %{_sysconfdir}/pdnssoc/misp_domains.txt
%config(noreplace) %{_sysconfdir}/pdnssoc/pdnssoc.conf
%config(noreplace) %{_sysconfdir}/pdnssoc/td-agent.conf.template
%{_sysconfdir}/pdnssoc/notification_email.html

# Code of pdnssoc
%dir /usr/local/bin/pdnssoc

%files doc
%doc %{gem_docdir}

%post
# Enable Timers
%systemd_post pdnssoc.service pdnssoc.timer
%systemd_post lookingback.service lookingback.timer
%systemd_post misp_refresh.service misp_refresh.timer
# Start Fluentd
systemctl restart td-agent.service

%preun
%systemd_preun pdnssoc.service pdnssoc.timer
%systemd_preun lookingback.service lookingback.timer
%systemd_preun misp_refresh.service misp_refresh.timer

%postun
%systemd_postun_with_restart pdnssoc.service pdnssoc.timer
%systemd_postun_with_restart lookingback.service lookingback.timer
%systemd_postun_with_restart misp_refresh.service misp_refresh.timer

%changelog
* Mon Aug 10 2023  Pau Cutrina, Romain Wartel, Christos Arvanitis <admin@safer-trust.org> - 1.0-1
- Changes to make it more GEM standard
* Mon Aug 07 2023 Pau Cutrina, Romain Wartel, Christos Arvanitis <admin@safer-trust.org> - 1.0-1
- Initial RPM package
