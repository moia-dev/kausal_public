local k = import "kausal.libsonnet";

k {
  local container = $.core.v1.container,

  local configYaml = std.native("parseYaml")("---
modules:
  http_2xx_example:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
      tls_config:
        insecure_skip_verify: false
      preferred_ip_protocol: "ip4"
    "),

  blackbox_exporter_config::
    configYaml

  local configMap = $.core.v1.configMap,

  blackbox_exporter_config_map:
    configMap.new("blackbox-exporter-config") +
    configMap.withData({
      "blackbox.yaml": $.util.manifestYaml($.blackbox_exporter_config),
    }),

  blackbox_exporter_container::
    container.new("blackbox-exporter", "prom/blackbox-exporter:latest") +
    container.withPorts($.core.v1.containerPort.new("http-metrics", 9115)) +
    container.withArgs([
      "--config.file=/config/blackbox.yaml",
    ]) +
    $.util.resourcesRequests("10m", "20Mi") +
    $.util.resourcesLimits("20m", "40Mi"),

  local deployment = $.apps.v1beta1.deployment,

  blackbox_exporter_deployment:
    deployment.new("blackbox-exporter", 1, [
      $.blackbox_exporter_container,
    ]) +
    $.util.configVolumeMount("blackbox-exporter-config", "/config"),

  blackbox_exporter_service:
    $.util.serviceFor($.blackbox_exporter_deployment),
}