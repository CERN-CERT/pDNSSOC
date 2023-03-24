module ConstantsConfig
    # If the env variables are not defined, use the default values
    PATH_LOG = ENV['PATH_LOG'] || "/var/log/td-agent/"
    PATH_PDNS_CONF = ENV['PATH_PDNS_CONF'] || "/etc/pdnssoc/pdnssoc.conf"
    PATH_MISP_D = ENV['PATH_MISP_D'] || "/etc/td-agent/misp_domains.txt"
    PATH_HTML = ENV['PATH_HTML'] || "/etc/pdnssoc/structure_html.txt"
    FILENAME_LOG_ALERT = ENV['FILENAME_LOG_ALERT'] || "alerts.log"
    FILENAME_LOG_SYS = ENV['FILENAME_LOG_SYS'] || "pdnssoc_sys.log"
end

module ConstantsEmail
    HTML_ALERT_CELL = '<td style="text-align: left;" rowspan="%{r}">%{s}</td>'
    HTML_MISP_CELL = '<td style="text-align: left;">%{n}</td>'
    HTML_MISP_TAG = '<span style="background: %{c};"><b><span style="color: #fff; mix-blend-mode: difference; padding: 5px; ">%{n}</span></b></span>'
    HTML_MISP_LINK = '<a href="%{i}" target="_new">%{m}</a>'
    HTML_TITLE = '<th>%{n}</th>'

    TABLE_STRUCTURE = {
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