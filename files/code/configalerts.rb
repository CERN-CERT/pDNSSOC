require "json"
require 'logger'
require "time"
require 'parseconfig'
require_relative 'constants'


module ConfigAlerts
  include ConstantsConfig
  include ConstantsErrors

  def initialize()
    # Setup Logging
    @@log_alerts = Logger.new(PATH_LOG + FILENAME_LOG_ALERT, 'daily')
    @@log_alerts.formatter = proc do |severity, datetime, progname, msg| {message: msg}.to_json + $/ end
    @@log_sys = Logger.new(PATH_LOG + FILENAME_LOG_SYS, 'daily')
    @@log_sys.formatter = proc do |severity, datetime, progname, msg| "#{datetime}, #{severity}: #{msg} #{progname} \n" end
    # Open config files
    @@misp_config, @@alerts_config, @@email_config, @@pdns_config = init_config()
    # Get the list of bad domains
    @@bad_domains = File.read(PATH_MISP_D)
    # Get HTML template for the email
    @@html_email = init_html()
  end 

  def init_html()
    html_data = ""
    # Template HTML of the email
    f = File.open(PATH_HTML, "r") 
    f.each_line do |line| html_data += line end
    raise TypeError, "html_data expected an String, got #{html_data.class.name}" unless html_data.kind_of?(String)
    return html_data
  end 

  def init_config()
    config_data = JSON.parse(File.read(PATH_PDNS_CONF))
    # Initialize vaiables
    misp_config = config_data["misp_servers"]
    alerts_config = config_data["alerts_path"]
    email_config = config_data["email"]
    pdns_config = config_data["pdns_client"]
    # Check if they all have the expected format
    bool_conf = (misp_config.kind_of?(Array) and alerts_config.kind_of?(String) and email_config.kind_of?(Hash) and pdns_config.kind_of?(Hash))
    # Check if all the required info is present
    if bool_conf
      misp_subconf = params_to_check(misp_config, ['domain', 'api_key', 'parameter'])
      email_subconf = params_to_check(email_config, ['from', 'to', 'subject', 'server', 'port'])
    end
    # If some field is missing or empty the code breaks
    if ! (bool_conf and misp_subconf and email_subconf)
      @@log_sys.error(CONFIGFILE) #+ "Backtrace: " + e.backtrace.join(" / "))
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
  
