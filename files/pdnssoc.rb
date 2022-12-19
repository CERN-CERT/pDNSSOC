require "misp"
require "json"
require 'net/smtp'
require 'parseconfig'

# events = MISP::Event.search(info: "test")
#events = MISP::Event.get(39143)

#event = MISP::Event.search(info: "Phishing indicators 31/22")
#events = MISP::Event.search(info: "test")
#
#puts  attributes.inspect
#puts event.methods.sort

#File.readlines('/var/log/td-agent/td-agent.log').each do |line|

class ConfigAlerts
  @@config = JSON.parse(File.read("/etc/pdnssoc/pdnssoc.conf"))
  #@@config = JSON.parse(File.read("./pdnssoc_conf.json"))
  @@bad_domains = File.read("/etc/td-agent/misp_domains.txt")
end

class Alert < ConfigAlerts
  # Convert a log to a alert json
  def initialize(json_log)
    @json_log = json_log
  end

  def query_misp(misp_url, misp_api_key, domain, all_uuids)
    result_misp = []
    list_uuids = []
    # Setup config MISP server
    MISP.configure do |config|
      config.api_endpoint = misp_url
      config.api_key = misp_api_key
    end   

    # Search
    misp_events = MISP::Event.search(type: "domain", value: domain)

    # One domain can have multiple events associated
    for misp_event in misp_events
      # If there's a valid event and we did not processed it before proceed
      if not all_uuids.include? misp_event.uuid
        $misp_link = misp_url+"events/view/"+misp_event.id
        $domain_link = misp_url+"index/searchall:"+domain

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
              'misp_link' => $misp_link,
              'domain_link' => $domain_link,
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

  def parse_log()
    results = {}
    $malicious_domain = @json_log["query"]
    # MISP Query
    events = []
    events_uuid = []
    for misp_server in @@config["misp_servers"]
      events_uuid = events_uuid.flatten
      events_detected, uuids=query_misp(misp_server["url"], misp_server["api_key"], $malicious_domain, events_uuid)

      if events_detected.length > 0
        events_uuid.append(uuids)
        events.append(events_detected)
      end
    end
    events = events.flatten

    $num_misp_events = events.length()

    if $num_misp_events > 0
      results = {
        'client' => @json_log["client"],
        'count' => 0,
        'first_occurrence' => @json_log["date"],
        'domain' => $malicious_domain,
        'domain_link' => $domain_link,
        "misp" => events
      }
    end
    return results
  end
end


class Email < ConfigAlerts
  def initialize()
    @email_config = @@config["email"]
    @pdns_config = @@config["pdns_client"]
    
    @html_alert_cell = '<td style="text-align: left;" rowspan="%{r}">%{s}</td>'
    @html_misp_cell = '<td style="text-align: left;">%{n}</td>'
    @html_misp_tag = '<span style="background: %{c};"><b><span style="color: #fff; mix-blend-mode: difference; padding: 5px; ">%{n}</span></b></span>'
    @html_link_misp = '<a href="%{i}" target="_new">%{m}</a>'
    @html_title = '<th>%{n}</th>'

    @table_structure = {
            "general" => [
              {"title" => "pDNSSOC client", "misp_ref" => ""}, 
              {"title" => "First Occurrence", "misp_ref" => "first_occurrence"},
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

  def get_file_as_string(filename)
    data = ''
    f = File.open(filename, "r") 
    f.each_line do |line|
      data += line
    end
    return data
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
    ip_client = result_json["client"]
    
    # pDNS Client
    if @pdns_config[ip_client] and @pdns_config[ip_client].keys.include?("name")
      pdns_client = @pdns_config[result_json["client"]]["name"]
      client_info = "%{n} (%{m})" % [n: pdns_client, m: result_json["client"]]
      $result_html += @html_alert_cell % [r: num_events, s: client_info]
    else
      $result_html += get_html(@html_alert_cell, result_json["client"], [], num_events)
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
      result_html = result_to_html(result)
      @html_table_results += result_html
    end

  end

  def send_email()
    html_data = get_file_as_string "/etc/pdnssoc/structure_html.txt"

    # Create html header/title
    titles = "<tr>"
    for structure in @table_structure["general"].concat(@table_structure["misp_specific"])
      titles += @html_title % [n: structure["title"]]
    end
    titles += "</tr>"

    @email_html = html_data % [data: titles + @html_table_results]

    message = <<~MESSAGE_END
    From: #{@email_config["from"]} 
    To: #{@email_config["to"]}
    MIME-Version: 1.0
    Content-type: text/html
    Subject: #{@email_config["subject"]}

    #{@email_html}
    
    MESSAGE_END

    Net::SMTP.start(@email_config["server"], @email_config["port"]) do |smtp|
      smtp.send_message message, @email_config["from"], @email_config["to"]
      puts "Email sent"
    end
  end

end 


class Trigger < ConfigAlerts

  def initialize()
    @alerts_path = @@config['alerts_path']
    @alerts, @processed_logs = get_path_logs()
    @all_results = {}
  end

  def get_path_logs()
    @alerts = ""
    @processed_logs = []
    Dir.glob(@alerts_path + "*.log") do |filename|
    #Dir.glob("testlogs/" + "*.log") do |filename|
      #puts "working on: #{filename}"
      File.readlines(filename).each do |line|
      #   puts(line)
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

  def run()
    @alerts.each_line do |line|
        json_log_read = JSON.parse(line)
        domain = json_log_read["query"]
        if @@bad_domains.include?(domain)
            if ! @all_results.keys.include?(domain)
                alert = Alert.new(json_log_read)
                results = alert.parse_log()
                if results != {}
                @all_results[domain] = results
                end
            else
                @all_results[domain]["count"] += 1
            end
        end      
    end

    if @all_results != {}
      email = Email.new()
      email.all_results_to_html(@all_results)
      email.send_email()
    else
      puts "No alerts found!"
    end

    delete_logs()

  end

end

trigger = Trigger.new()
trigger.run()
