require_relative 'configalerts'
require_relative 'email'
require_relative 'alerts'
require_relative 'constants'
require "time"

class Trigger 
  include ConfigAlerts

  def initialize()
    super()
    @alerts, @processed_logs = get_path_logs()
  end

  def get_path_logs()
    @alerts = ""
    @processed_logs = []
    Dir.glob(@@alerts_config + "*.log") do |filename|
      File.readlines(filename).each do |line|
        @alerts += line
      end
      @processed_logs.append(filename)
    end
    return @alerts, @processed_logs
  end

  def delete_logs()
    for filename in @processed_logs
      @@log_sys.debug("Deleting: " + filename)
      File.delete(filename) if File.exist?(filename)
    end
  end

  def retreive_data(domain)
    # If we already have the info for this domain -> +1
    results = ""
    return results
  end

  def get_email_client(ip_client)
    # TODO: Given a boolean, skip any event from clients that are not on the config file
    
    # If we have email for that client we will contact them directly
    if @@pdns_config.keys.include?(ip_client) and @@pdns_config[ip_client].keys.include?("email") and ! @@pdns_config[ip_client]["email"].empty?
      email_client = @@pdns_config[ip_client]["email"]
    else
      # If we don't have the email of the clientb we send the email to the default security contact
      email_client = @@email_config["to"]
    end
    return email_client
  end 

  def run()
    skip_domains = []
    skip_misp_servers = []
    all_alerts = {}
    # Read each line of the log wrote by fluentd
    @alerts.each_line do |line|
      json_log_read = JSON.parse(line)
      begin
        domain = json_log_read["query"]
        ip_client = json_log_read["client"]
        first_occurrence = json_log_read["date"]
        email_client = get_email_client(ip_client)
        # Domains that are legit or that do not have information in MISP will be skipped
        if ! skip_domains.include?(domain)
          # If it is a malicious domain
          if @@bad_domains.include?(domain)
            # If it was already analyzed -> +1
            if ! all_alerts.empty? and all_alerts.include?(email_client) and all_alerts[email_client].include?(domain)
              all_alerts[email_client][domain]["count"] += 1
            else 
              # We don't have information so we will query MISP
              alert = Alert.new()
              @data_malicious_domain = alert.parse_log(domain, ip_client, first_occurrence, skip_misp_servers)
              # If we detected that there are MISP servers that fail we will skip it/them next time
              faulty_misp = alert.get_faulty_misp()
              if ! faulty_misp.empty?
                skip_misp_servers = skip_misp_servers.concat(faulty_misp).uniq
              end
            end
            if @data_malicious_domain.empty?            
              # Although it is a malicious domain it doesn't have any data in MISP -> skip next time
              skip_domains.append(domain)
            else
              # We have found data in MISP about this domain -> we will report it to the right client
              if ! all_alerts.include?(email_client)
                all_alerts[email_client] = {}
              end
              all_alerts[email_client][domain] = @data_malicious_domain
              @@log_alerts.info(@data_malicious_domain)
            end  
          else
            skip_domains.append(domain)
          end
        end
      rescue Exception => e
        raise Exception, TRIGGER_ERROR % [e:e]
      end
    end

    if all_alerts.empty?
      @@log_sys.debug("No alerts found!")
    else
      # We will send an alert to each client (with an email on the config file) and to the general security contact
      all_alerts.each do |email_client, client_data|
        email = Email.new()
        message = email.build_email(client_data)
        email.send_email(email_client, message) 
      end
      # If the send_email is not successful the logs will not be deleted
      delete_logs()
    end
  end
end
