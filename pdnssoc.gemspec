Gem::Specification.new do |spec|
  spec.name                  = 'pdnssoc'
  spec.version               = '0.1.0'
  spec.authors               = ['Pau Cutrina', 'Romain Wartel', 'Christos Arvanitis']
  spec.email                 = ['csirt@safer-trust.org']
  spec.required_ruby_version = '>= 2.5.0'
  spec.metadata              = { 'rubygems_mfa_required' => 'true' }

  spec.summary     = 'pDNS correlation with MISP'
  spec.description = 'pDNS correlation with MISP'
  spec.homepage    = 'https://github.com/CERN-CERT/pDNSSOC/'
  spec.license     = 'MIT'

  spec.files         = Dir['files/**/*'] + ['Rakefile', 'Gemfile', 'README.md', 'CHANGELOG.md', '.gitignore']

  spec.add_runtime_dependency 'parseconfig'
  spec.add_runtime_dependency 'misp'
  spec.add_runtime_dependency 'fluent-plugin-filter-list'


  spec.metadata['source_code_uri'] = 'https://github.com/CERN-CERT/pDNSSOC'
  spec.metadata['changelog_uri']   = 'https://github.com/CERN-CERT/pDNSSOC/blob/master/CHANGELOG.md'
  spec.metadata['homepage_uri']    = 'https://github.com/CERN-CERT/pDNSSOC'

  spec.requirements << 'Ruby (>= 2.5.0)'
end
