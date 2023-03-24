require 'net/smtp'
require_relative 'constants'



class Email 
  include ConfigAlerts
  include ConstantsEmail
  include ConstantsErrors

    def initialize()    
      @html_table_results = ""
    end
  
    def get_html(ref_html, data, list_params=[], index="")
      html_append = ""
      if list_params == []
        html_append += ref_html % [r: index, s: data]
      else
        for ref_result in list_params
          if ref_result["misp_ref"].is_a? Hash and ref_result["misp_ref"] != {}
            link_html = HTML_MISP_LINK % [i: data[ref_result["misp_ref"]["link"]], m:data[ref_result["misp_ref"]["ref"]]]
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
        $result_html += HTML_ALERT_CELL % [r: num_events, s: client_info]
      else
        $result_html += get_html(HTML_ALERT_CELL, result_json["client_ip"], [], num_events)
      end
  
      $result_html += get_html(HTML_ALERT_CELL, result_json, TABLE_STRUCTURE["general"], num_events)
      $num_event = 0 
  
      for event in result_json["misp"] do
        if $num_event != 0 
          $result_html += "<tr>"
        end  
  
        $result_html += get_html(HTML_MISP_CELL, event, TABLE_STRUCTURE["misp_specific"])
        $misp_tags = ""
  
        for tag in event["tags"] do
          $misp_tags +=  HTML_MISP_TAG % [c: tag["colour"], n: tag["name"]]
        end
      
        $result_html += HTML_MISP_CELL % [n: $misp_tags]
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
      for structure in TABLE_STRUCTURE["general"].concat(TABLE_STRUCTURE["misp_specific"])
        titles += HTML_TITLE % [n: structure["title"]]
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
      begin
        Net::SMTP.start(@@email_config["server"], @@email_config["port"]) do |smtp|
          smtp.send_message message, @@email_config["from"], email_to end
      rescue Exception => e
          @@log_sys.error(SMTP_ERROR + e.message) #+ "Backtrace: " + e.backtrace.join(" / "))
          raise Exception,  SMTP_ERROR + e.message
        end
    end
  
  end 