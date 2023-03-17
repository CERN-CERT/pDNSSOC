require "misp"
require "json"
require "time"
require 'logger'
require 'net/smtp'
require 'parseconfig'

# events = MISP::Event.search(info: "test")
#events = MISP::Event.get(39143)

#event = MISP::Event.search(info: "Phishing indicators 31/22")
#events = MISP::Event.search(info: "test")
# 
#puts  attributes.inspect
#puts event.methods.sort

$stdout.sync = true

class ConfigAlerts
  def initialize()
    # Files used
    @@PATH_LOG = "/var/log/td-agent/"
    @@PATH_PDNS_CONF = "/etc/pdnssoc/pdnssoc.conf"
    @@PATH_MISP_D = "/etc/td-agent/misp_domains.txt"
    @@PATH_HTML = "/etc/pdnssoc/structure_html.txt"
    # Setup Logging -> alerts.log with the results (i.e. for the SIEM) and pdnssoc_sys.log with the debug logs
    @@log_alerts = Logger.new(@@PATH_LOG + "alerts.log", 'daily')
    @@log_alerts.formatter = proc do |severity, datetime, progname, msg| {message: msg}.to_json + $/ end
    @@log_sys = Logger.new(@@PATH_LOG + "pdnssoc_sys.log", 'daily')
    @@log_sys.formatter = proc do |severity, datetime, progname, msg| "#{datetime}, #{severity}: #{msg} #{progname} \n" end
    # Open config files
    @@misp_config, @@alerts_config, @@email_config, @@pdns_config = init_config()
    # Get the list of bad domains
    @@bad_domains = File.read(@@PATH_MISP_D)
    # Get HTML template for the email
    @@html_email = init_html()
  end 

  def init_html()
    html_data = ""
    # Template HTML of the email
    f = File.open(@@PATH_HTML, "r") 
    f.each_line do |line| html_data += line end
    raise TypeError, "html_data expected an String, got #{html_data.class.name}" unless html_data.kind_of?(String)
    return html_data
  end 

  def init_config()
    config_data = JSON.parse(File.read(@@PATH_PDNS_CONF))
    # Initialize vaiables
    misp_config = config_data["misp_servers"]
    alerts_config = config_data["alerts_path"]
    email_config = config_data["email"]
    pdns_config = config_data["pdns_client"]
    # Check if they all have the expected format
    bool_conf = (misp_config.kind_of?(Array) and alerts_config.kind_of?(String) and email_config.kind_of?(Hash) and pdns_config.kind_of?(Hash))
    # Check if all the required info is present
    if bool_conf
      misp_subconf = params_to_check(misp_config, ['url', 'api_key', 'parameter'])
      email_subconf = params_to_check(email_config, ['from', 'to', 'subject', 'server', 'port'])
    end
    # If some field is missing or empty the code breaks
    if ! (bool_conf and misp_subconf and email_subconf)
      error_message = "ConfigFileError. Some parameters of your config file are either missing or have a wrong format. "
      @@log_sys.error(error_message) #+ "Backtrace: " + e.backtrace.join(" / "))
      raise (error_message)  
    end
    return misp_config, alerts_config, email_config, pdns_config 
  end

  def params_to_check(configuration, params)
    # Iterate over all the params to make sure they are on the config file
    for param in params
      # If it is an array you want to check the inner maps
      if configuration.kind_of?(Array)
        for map in configuration 
          if ! param_in_map(param,map)  
            return false 
          end 
        end
      else
        if ! param_in_map(param,configuration) 
          return false 
        end
      end
    return true
    end 
  end

  def param_in_map(param,map)
    # If the param is not on the map or if it is empy -> False
    bool = map.keys.include?(param) and ! map[param].empty?
    return bool
  end

end

class Alert < ConfigAlerts

  def query_misp(misp_url, misp_api_key, domain, all_uuids)
    result_misp = []
    list_uuids = []
    # Setup config MISP server
    MISP.configure do |config|
      config.api_endpoint = misp_url
      config.api_key = misp_api_key
    end   

    # Search
    misp_events = []
    begin
      misp_events = MISP::Event.search(type: "domain", value: domain)
    rescue Exception => e
      error_message = "MISP query failed using %{u} with the error message -> " % [u:misp_url]
      @@log_sys.error(error_message + e.message)
    end

    # One domain can have multiple events associated
    for misp_event in misp_events
      # If there's a valid event and we did not processed it before proceed
      if not all_uuids.include? misp_event.uuid
        misp_link = misp_url + "events/view/" + misp_event.id
        domain_link = misp_url + "index/searchall:" + domain

        # Find the attribute where the malicious domain is defined
        for attribute in misp_event.attributes
          if attribute.type == "domain" and attribute.value == domain and attribute.to_ids == true
            $tags = []
            for tag in attribute.tags do
              $tags.append({"colour" => tag.colour, "name" => tag.name})
            end
            event = {
              'misp_uuid' => misp_event.uuid,
              'misp_info' => misp_event.info,
              'misp_link' => misp_link,
              'domain_link' => domain_link,
              'num_iocs' => misp_event.attribute_count,
              'publication' => misp_event.date,
              'organisation' => misp_event.orgc.name,
              'comment' => attribute.comment,
              'tags' => $tags
            }
            list_uuids.append(misp_event.uuid)
            result_misp.append(event)
            break
          end
        end
      end
    end
          
    return result_misp, list_uuids
  end

  def get_client_info(ip_client, key_reference)
    pdns_client = ""
    if @@pdns_config[ip_client] 
      # If the name is present on the configuration file we will use it on the email. Otherwise we will just use the ip
      if @@pdns_config[ip_client].keys.include?(key_reference) and ! @@pdns_config[ip_client][key_reference].empty?
        pdns_client = @@pdns_config[ip_client][key_reference]
      end
    else
      error_message = "An unknown client %{c} has been detected. Add it on the configuration file to receive alerts. " % [c:ip_client]
      @@log_sys.error(error_message)
    end
    return pdns_client
  end

  def parse_log(domain, ip_client, date)
    result_domain = {}
    name_client = get_client_info(ip_client, "name") 
    # MISP Query
    events = []
    events_uuid = []

    # For each MISP server query the malicious domain
    for misp_server in @@misp_config
      events_uuid = events_uuid.flatten
      events_detected, uuids = [], []
      events_detected, uuids=query_misp(misp_server["url"], misp_server["api_key"], domain, events_uuid)
      if events_detected.length > 0
        events_uuid.append(uuids)
        events.append(events_detected)
      end
    end
    events = events.flatten
    $num_misp_events = events.length()

    if $num_misp_events > 0
      result_domain = {
        'client_ip' => ip_client,
        'client_name' => name_client,
        'count' => 1,
        'timestamp' => Time.parse(date).to_i,
        'domain' => domain,
        'domain_link' => $domain_link,
        "misp" => events
      }
    end

    return result_domain
  end
end


class Email < ConfigAlerts
  def initialize()    
    @html_alert_cell = '<td style="text-align: left;" rowspan="%{r}">%{s}</td>'
    @html_misp_cell = '<td style="text-align: left;">%{n}</td>'
    @html_misp_tag = '<span style="background: %{c};"><b><span style="color: #fff; mix-blend-mode: difference; padding: 5px; ">%{n}</span></b></span>'
    @html_link_misp = '<a href="%{i}" target="_new">%{m}</a>'
    @html_title = '<th>%{n}</th>'

    @table_structure = {
            "general" => [
              {"title" => "pDNSSOC client", "misp_ref" => ""}, 
              {"title" => "First Occurrence", "misp_ref" => "timestamp"},
              {"title" => "Malicious domain", "misp_ref" => {"ref" => "domain", "link" => "domain_link"}}],
            "misp_specific" => [
              {"title" => "MISP event", "misp_ref" => {"ref" => "misp_info", "link" => "misp_link"}},
              {"title" => "Total # of IoCs", "misp_ref" => "num_iocs"},
              {"title" => "Publication", "misp_ref" => "publication"},
              {"title" => "Organisation", "misp_ref" => "organisation"},
              {"title" => "Comment", "misp_ref" => "comment"},
              {"title" => "Tags", "misp_ref" => ""}]}

    @html_table_results = ""
  end

  def get_html(ref_html, data, list_params=[], index="")
    html_append = ""
    if list_params == []
      html_append += ref_html % [r: index, s: data]
    else
      for ref_result in list_params
        if ref_result["misp_ref"].is_a? Hash and ref_result["misp_ref"] != {}
          link_html = @html_link_misp % [i: data[ref_result["misp_ref"]["link"]], m:data[ref_result["misp_ref"]["ref"]]]
          data_ref = link_html
        else
          data_ref = data[ref_result["misp_ref"]]
        end
        if ref_result["misp_ref"] != ""
          if index == ""

            html_append += ref_html % [n: data_ref]
          else
            html_append += ref_html % [r: index, s: data_ref]
          end
        end
      end
    end
    return html_append
  end


  def result_to_html(result_json)
    # converts results of one domain (one row of the table) to HTML
    $result_html = '<tr>'
    num_events = result_json["misp"].length
    
    # pDNS Client
    if ! result_json["client_name"].empty?
      client_info = "%{n} (%{m})" % [n: result_json["client_name"], m: result_json["client_ip"]]
      $result_html += @html_alert_cell % [r: num_events, s: client_info]
    else
      $result_html += get_html(@html_alert_cell, result_json["client_ip"], [], num_events)
    end

    $result_html += get_html(@html_alert_cell, result_json, @table_structure["general"], num_events)
    $num_event = 0 

    for event in result_json["misp"] do
      if $num_event != 0 
        $result_html += "<tr>"
      end  

      $result_html += get_html(@html_misp_cell, event, @table_structure["misp_specific"])
      $misp_tags = ""

      for tag in event["tags"] do
        $misp_tags +=  @html_misp_tag % [c: tag["colour"], n: tag["name"]]
      end
    
      $result_html += @html_misp_cell % [n: $misp_tags]
      $result_html += "</tr>"
      $num_event += 1
    end
    return $result_html
  end

  def all_results_to_html(all_results_json)
    all_results_json.each do |domain, result|
      @@log_alerts.info(result)
      result_html = result_to_html(result)
      @html_table_results += result_html
    end

  end

  def build_email()
    # Create html header/title
    titles = "<tr>"
    for structure in @table_structure["general"].concat(@table_structure["misp_specific"])
      titles += @html_title % [n: structure["title"]]
    end
    titles += "</tr>"

    @email_html = @@html_email % [data: titles + @html_table_results]

    message = <<~MESSAGE_END
    From: #{@@email_config["from"]} 
    To: #{@@email_config["to"]}
    MIME-Version: 1.0
    Content-type: text/html
    Subject: #{@@email_config["subject"]}

    #{@email_html}
    
    MESSAGE_END
    return message
  end

  def send_email(email_to, message)
    Net::SMTP.start(@@email_config["server"], @@email_config["port"]) do |smtp|
      smtp.send_message message, @@email_config["from"], email_to end
  end

end 


class Trigger < ConfigAlerts

  def initialize()
    super()
    @alerts, @processed_logs = get_path_logs()
  end

  def get_path_logs()
    @alerts = ""
    @processed_logs = []
    Dir.glob(@@alerts_config + "*.log") do |filename|
    #Dir.glob("testlogs/" + "*.log") do |filename|
      File.readlines(filename).each do |line|
        @alerts += line
      end
      @processed_logs.append(filename)
    end
    return @alerts, @processed_logs
  end

  def delete_logs()
    for filename in @processed_logs
      puts("Deleting: " + filename)
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
            if ! all_alerts.empty? and all_alerts.keys.include?(email_client) and all_alerts[email_client].keys.include?(domain)
              all_alerts[email_client][domain]["count"] += 1
            else 
              # We don't have information so we will query MISP
              alert = Alert.new()
              @data_malicious_domain = alert.parse_log(domain, ip_client, first_occurrence)
            end
            if @data_malicious_domain.empty?            
              # Although it is a malicious domain it doesn't have any data in MISP -> skip next time
              skip_domains.append(domain)
            else
              # We have found data in MISP about this domain -> we will report it to the right client
              all_alerts[email_client] = {domain: @data_malicious_domain}
            end  
          else
            skip_domains.append(domain)
          end
        end
      rescue Exception => e
        raise Exception, "DNS/pDNS queries cannot be read. %{e}" % [e:e]
      end
    end

    if all_alerts.empty?
      puts "No alerts found!"
    else
      # We will send an alert to each client (with an email on the config file) and to the general security contact
      all_alerts.each do |email_client, client_data|
        email = Email.new()
        email.all_results_to_html(client_data)
        message = email.build_email()
        begin
          email.send_email(email_client, message) 
        rescue Exception => e
          error_message = "The email could not be sent. Check the SMTP configuration."
          @@log_sys.error(error_message + e.message) #+ "Backtrace: " + e.backtrace.join(" / "))
          raise Exception,  error_message + e.message
        end
      end
      # If the send_email is not successful the logs will not be deleted
      delete_logs()
    end
  end
end

trigger = Trigger.new()
trigger.run()
