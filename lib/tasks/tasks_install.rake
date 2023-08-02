require 'rake'
require 'fileutils'
require 'whenever'

pdnssoc_workdir = Dir.pwd

ENV['WORK_DIR_pDNSSOC'] = pdnssoc_workdir

# Defines the tasks that will be triggered by lib/post_install.rb
namespace :rake_install do
  # Task to install system packages and pDNSSOC files
  task :install do
    # Clean installation files
    puts "Cleaning the room."
    FileUtils.rm_f("/etc/cron.hourly/pdnssoc_misp")
    system("sed '/pdnssoc\.rb/d' -i /etc/crontab 2>/dev/null")
    system("sed '/lookingback/d' -i /etc/crontab 2>/dev/null")
    puts "Creating empty directories and files necessary"
    # Install fluentd 
    system('curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh')
    if !File.exist?('/etc/td-agent/td-agent.conf')
      td_agent_file = File.join(pdnssoc_workdir, 'config', 'td-agent.conf')
      FileUtils.cp(td_agent_file, '/etc/td-agent/td-agent.conf')
    end
    system('td-agent-gem install parseconfig;td-agent-gem install misp')
    # Create the logging and fluentd directories
    FileUtils.mkdir_p('/var/log/td-agent/')
    dir_tdagent = '/etc/td-agent/'
    FileUtils.mkdir_p(dir_tdagent)
    FileUtils.chown('td-agent', 'td-agent', dir_tdagent)
    FileUtils.touch('/etc/td-agent/misp_domains.txt')
    FileUtils.touch('/etc/td-agent/misp_ips.txt')
    # Create pdnssoc directory
    FileUtils.mkdir_p('/etc/pdnssoc/')
    FileUtils.ln_s(File.join(pdnssoc_workdir, 'config', 'pdnssoc.conf'), '/etc/pdnssoc/', force: true)
    # Add the cronjobs that will keep pdnssoc running
    schedule_file = File.join(pdnssoc_workdir, 'config', 'schedule.rb')
    command = "whenever --update-crontab --load-file #{schedule_file}"
    system("bundle exec #{command}")
    # Create a symbolic link so the cronjob is scheduled
    gem_cron_file = File.join(pdnssoc_workdir, 'cron', 'pdnssoc.cron')
    FileUtils.cp(gem_cron_file, '/etc/cron.hourly/pdnssoc_misp')
    # Start Fluentd
    puts "Starting Fluentd."
    system('systemctl restart td-agent.service')
  end
end

task :default => 'rake_install:install'
