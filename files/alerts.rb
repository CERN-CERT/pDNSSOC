require "misp"
require 'timeout'
require_relative 'configalerts'

class Alert
  include ConfigAlerts
  include ConstantsErrors
  include ConstantsAlerts

  @@faulty_misp_servers = []

  def get_faulty_misp()
    return @@faulty_misp_servers
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
    misp_events = []
    begin
      Timeout::timeout(TIMEOUT_MISP_QUERY) {
        misp_events = MISP::Event.search(type: "domain", value: domain)
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
      }
    rescue Exception => e
      error_message = MISPQUERY % [u:misp_url]
      @@log_sys.error(error_message + e.message)
      @@faulty_misp_servers.append(misp_url)
    ensure
      return result_misp, list_uuids
    end
  end

  def get_client_info(ip_client, key_reference)
    pdns_client = ""
    if @@pdns_config[ip_client] 
      # If the name is present on the configuration file we will use it on the email. Otherwise we will just use the ip
      if @@pdns_config[ip_client].keys.include?(key_reference) and ! @@pdns_config[ip_client][key_reference].empty?
        pdns_client = @@pdns_config[ip_client][key_reference]
      end
    else
      @@log_sys.error(UNKNOWN_CLIENT % [c:ip_client])
    end
    return pdns_client
  end

  def parse_log(domain, ip_client, date, faulty_misp)
    result_domain = {}
    name_client = get_client_info(ip_client, "name") 
    # MISP Query
    events = []
    events_uuid = []

    for misp_server in @@misp_config
      if ! faulty_misp.include?(misp_server["url"]) 
        events_uuid = events_uuid.flatten
        events_detected, uuids=query_misp(misp_server["url"], misp_server["api_key"], domain, events_uuid)
        if events_detected.length > 0
          events_uuid.append(uuids)
          events.append(events_detected)
        end
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
  