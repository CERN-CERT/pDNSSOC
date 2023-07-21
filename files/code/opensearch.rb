require 'opensearch'

class Opensearch
  include ConfigAlerts
  include ConstantsErrors
  include ConstantsGeneral

  def send_alert(results)
    begin
      client = Opensearch::Client.new(
        url: @@opensearch_config["server"],
        user: @@opensearch_config["username"],
        password: @@opensearch_config["password"],
        transport_options: { ssl: { verify: false } },
        log: true
      )

      results.each do |ioc, data_ioc|
        data_ioc["misp"].each_with_index do |misp_event, idx_event|
          document = {
            '@timestamp': Time.at(data_ioc["first_occurrence"]).strftime(TIME_FORMAT_YMD),
            'source': 'pdnssoc',
            'src_ip': data_ioc["client_ip"],
            'ioc_detected': data_ioc["ioc_detected"],
            'misp': {
              'link': misp_event["misp_server"] + "/events/view/" + misp_event["misp_id"],
              'misp_info': misp_event["misp_info"],
              'num_iocs': misp_event["num_iocs"],
              'publication': misp_event["publication"],
              'organisation': misp_event["organisation"],
              'comment': misp_event["comment"],
              'tags': []
            }
          }

          response = client.index(
            index: @@opensearch_config["index"],
            body: document,
            refresh: true
          )
        end
      end
    end
end