require 'rake'
require 'fileutils'
require 'whenever'

pdnssoc_workdir = Dir.pwd

ENV['WORK_DIR_pDNSSOC'] = pdnssoc_workdir

# Task to install system packages and pDNSSOC files
task :rake_install do
  # Clean installation files
  puts "Cleaning the room."
  FileUtils.rm_f("/etc/cron.hourly/pdnssoc_misp")
  system("sed '/pdnssoc\.rb/d' -i /etc/crontab 2>/dev/null")
  system("sed '/lookingback/d' -i /etc/crontab 2>/dev/null")
  # Create the logging and fluentd directories
  FileUtils.mkdir_p('/var/log/td-agent/')
  dir_tdagent = '/etc/td-agent/'
  FileUtils.mkdir_p('dir_tdagent')
  FileUtils.chown('td-agent', 'td-agent', dir_tdagent)
  # Install fluentd 
  system('curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh')
  td_agent_file = File.join(pdnssoc_workdir, 'config', 'td-agent.conf')
  FileUtils.ln_s(td_agent_file, '/etc/td-agent/td-agent.conf', force: true)
  # Add the cronjobs that will keep pdnssoc running
  schedule_file = File.join(pdnssoc_workdir, 'config', 'schedule.rb')
  command = "whenever --update-crontab --load-file #{schedule_file}"
  #Whenever::CommandLine.execute(command: command)
  system("bundle exec #{command}")
  # Create a symbolic link so the cronjob is scheduled
  gem_cron_file = File.join(pdnssoc_workdir, 'cron', 'pdnssoc.cron')
  FileUtils.ln_s(gem_cron_file, '/etc/cron.hourly/pdnssoc_misp', force: true)
  # Start Fluentd
  puts "Starting Fluentd."
  system('systemctl restart td-agent.service')

end

task :default => :rake_install
