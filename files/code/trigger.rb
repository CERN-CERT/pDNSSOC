require_relative 'configalerts'
require_relative 'email'
require_relative 'alerts'
require_relative 'constants'
require_relative 'inputdata'
require "time"

class Trigger 
  include ConfigAlerts
  include InputData

  def initialize()
    super()
    @@alerts_found = {}
  end

  def delete_logs(processed_logs)
    for filename in processed_logs
      @@log_sys.debug("Deleting: " + filename)
      File.delete(filename) if File.exist?(filename)
    end
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

  def check_alert_keys(json_log_read)
    required_keys = ["query", "client", "date"]
    all_required_keys = required_keys.all? { |string| json_log_read.key?(string) }
    return all_required_keys
  end

  def study_ioc(list_iocs, ioc_detected, type_ioc, ip_client, date)
    skip_iocs = []
    # Domains that are legit or that do not have information in MISP will be skipped
    begin
      if ! skip_iocs.include?(ioc_detected)
        # If it is a malicious domain
        if list_iocs.include?(ioc_detected)
          email_client = get_email_client(ip_client)
          # If it was already analyzed -> +1
          if ! @@alerts_found.empty? and @@alerts_found.include?(email_client) and \
              @@alerts_found[email_client].include?(ioc_detected)
            @@alerts_found[email_client][ioc_detected]["count"] += 1
          else 
            # We don't have information so we will query MISP
            alert = Alert.new()                
            @result_ioc = alert.parse_log(ioc_detected, type_ioc, date, ip_client)
          end
          if @result_ioc.empty?            
            # Although it is a malicious domain it doesn't have any data in MISP -> skip next time
            skip_iocs.append(ioc_detected)
          else
            # We have found data in MISP about this domain -> we will report it to the right client
            if ! @@alerts_found.include?(email_client)
              @@alerts_found[email_client] = {}
            end
            @@alerts_found[email_client][ioc_detected] = @result_ioc
            @@log_alerts.info(@result_ioc)
          end
        else
          skip_iocs.append(ioc_detected)
        end
      end
    rescue Exception => e
      raise Exception, TRIGGER_ERROR % [e:e]
    end
  end

  def analyze_all_iocs(group_of_files)
    all_alerts = {}
    # Iterate over all files inside the group
    for filename in group_of_files
      # Read each line opf the file that represents one log entry
      File.readlines(filename).each do |line|
        json_log = JSON.parse(line)
          # If the data is not complete -> skip log
          if ! check_alert_keys(json_log)
            @@log_sys.error(MISSING_KEY_ALERT % line)
            next
          end
          ip_client = json_log["client"]
          date = Time.parse(json_log["date"]).to_i
          # If in addition of the domain, the resolved IP is provided, it will be analyzed
          if json_log.keys.include?("answer")
            study_ioc(@@bad_ips, json_log["answer"], "ip", ip_client, date)
          end 
          # Analyze if the domain is malicious
          study_ioc(@@bad_domains, json_log["query"], "domain", ip_client, date)
      end
    end
  end

  def run()
    # The files to process are gouped so in case of failure at least some of them will be processed
    groups = get_groups()
    for group_of_files in groups
      # Analyze all IOCs from the logs
      analyze_all_iocs(group_of_files)
      if @@alerts_found.empty?
        @@log_sys.debug("No alerts found!")
      else
        # We will send an alert to each client (with an email on the config file)
        @@alerts_found.each do |email_client, client_data|
          email = Email.new()
          email.send_email(email_client, client_data) 
        end
      end
      # If the send_email is not successful the logs will not be deleted
      #delete_logs(group_of_files)
    end
  end
end

