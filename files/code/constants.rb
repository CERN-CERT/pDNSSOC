module ConstantsConfig
    # If the env variables are not defined, use the default values
    PATH_LOG = ENV['PATH_LOG'] || "/var/log/td-agent/"
    PATH_PDNS_CONF = ENV['PATH_PDNS_CONF'] || "/etc/pdnssoc/pdnssoc.conf"
    PATH_MISP_D = ENV['PATH_MISP_D'] || "/etc/td-agent/misp_domains.txt"
    PATH_HTML = ENV['PATH_HTML'] || "/etc/pdnssoc/notification_email.html"
    FILENAME_LOG_ALERT = ENV['FILENAME_LOG_ALERT'] || "alerts.log"
    FILENAME_LOG_SYS = ENV['FILENAME_LOG_SYS'] || "pdnssoc_sys.log"
end

module ConstantsGeneral
    WEB_URL="https://%{d}"
    TIME_FORMAT_YMD = "%Y-%m-%dT%H:%M:%S.%L%z"

end

module ConstantsErrors
    CONFIGFILE = "ConfigFileError. Some parameters of your config file are either missing or have a wrong format. "
    MISPQUERY = "MISP query failed using %{u} and therefore will be skipped. The error message is -> "
    UNKNOWN_CLIENT="An unknown client %{c} has been detected. Add it on the configuration file to receive alerts. "
    TRIGGER_ERROR = "DNS/pDNS queries cannot be read. %{e}"
    SMTP_ERROR = "The email could not be sent. Check the SMTP configuration."

end

module ConstantsAlerts
    TIMEOUT_MISP_QUERY = ENV['TIMEOUT_MISP_QUERY'] || 20
end
