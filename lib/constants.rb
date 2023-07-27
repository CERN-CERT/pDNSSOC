
file_path = File.expand_path(__FILE__)
lib_path = File.dirname(file_path)
common_path = File.dirname(directory_path)

module ConstantsConfig
    # If the env variables are not defined, use the default values
    PATH_LOG = ENV['PATH_LOG'] || "/var/log/td-agent/"
    PATH_TDAGENT = "/etc/td-agent/"
    PATH_PDNS_CONF = ENV['PATH_PDNS_CONF'] || File.join(common_path, "config/pdnssoc.conf")
    PATH_MISP_D = ENV['PATH_MISP_D'] || File.join(PATH_TDAGENT, "misp_domains.txt")
    PATH_MISP_IP = ENV['PATH_MISP_D'] || File.join(PATH_TDAGENT, "misp_ips.txt")
    PATH_HTML = ENV['PATH_HTML'] || File.join(common_path, "config/notification_email.html")
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
    MISSING_KEY_ALERT =	"One of the keys is missing for: %s. This log entry will be skipped"

end

module ConstantsAlerts
    TIMEOUT_MISP_QUERY = ENV['TIMEOUT_MISP_QUERY'] || 20
end

module ConstantsData
    RGX_FILE_TIME = "/\d{8}-\d{4}/"
    PATH_ALERTS = PATH_LOG + 'pdnssoc-alerts/'
    RGX_FILE_REF = 'pdnssoc-buffer.*.log'
    GROUP_SIZE = 5 * 1024 * 1024
end

