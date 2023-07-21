require 'opensearch'

class Opensearch
  include ConfigAlerts
  include ConstantsErrors
  include ConstantsGeneral

  def send_alert(results)
    begin
    client = Opensearch::Client.new(
      url: @@opensearch_config["server"],
      username: @@opensearch_config["username"],
      password: @@opensearch_config["password"],
      log: true
    )

    client.cluster.health
    end
end