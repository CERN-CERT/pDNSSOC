
Gem::Specification.new do |spec|
  spec.name                  = 'pdnssoc'
  spec.version               = '0.1.4'
  spec.authors               = ['Pau Cutrina', 'Romain Wartel', 'Christos Arvanitis']
  spec.email                 = ['admin@safer-trust.org']
  spec.required_ruby_version = '>= 2.5.0'
  spec.metadata              = { 'rubygems_mfa_required' => 'true' }

  spec.summary     = 'pDNS correlation with MISP'
  spec.description = 'pDNS correlation with MISP'
  spec.homepage    = 'https://github.com/CERN-CERT/pDNSSOC/'
  spec.license     = 'MIT'

  spec.files         = Dir["lib/**/*", "config/**/*", "timers/**/*"]
  
  spec.metadata['source_code_uri'] = 'https://github.com/CERN-CERT/pDNSSOC'
  spec.metadata['changelog_uri']   = 'https://github.com/CERN-CERT/pDNSSOC/blob/master/CHANGELOG.md'
  spec.metadata['homepage_uri']    = 'https://github.com/CERN-CERT/pDNSSOC'
  spec.metadata['github_repo']    = 'ssh://github.com/CERN-CERT/pDNSSOC'
 
 spec.requirements << 'Ruby (>= 2.5.0)'

 spec.post_install_message = "pDNSSOC has been installed successfuly!"
end
