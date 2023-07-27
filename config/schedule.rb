set :job_template, "/bin/bash -l -c ':job'"

every 10.minutes do
  command "/opt/td-agent/bin/ruby #{ENV['WORK_DIR_pDNSSOC']}/lib/pdnssoc.rb"
end

every 1.day, at: '00:00' do
  command "/bin/bash #{ENV['WORK_DIR_pDNSSOC']}/bin/lookingback.sh"
end


