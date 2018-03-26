{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "splunk-kubernetes-logging.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "splunk-kubernetes-logging.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "splunk-kubernetes-logging.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Convert memory value from resources.limit to fluentd buffer.
Rules:
* fluentd does not support *i units
* fluentd does not support E and P
*/}}
{{- define "splunk-kubernetes-logging.convert-memory" -}}
{{- $mem := lower . -}}
{{- if hasSuffix "p" $mem -}}
{{- printf "%sT" (trimSuffix "p" $mem | atoi | mul 1000 | toString) -}}
{{- else if hasSuffix "pi" $mem -}}
{{- printf "%sT" (trimSuffix "pi" $mem | atoi | mul 1024 | toString) -}}
{{- else if hasSuffix "e" $mem -}}
{{- printf "%sT" (trimSuffix "e" $mem | atoi | mul 1000 1000 | toString) -}}
{{- else if hasSuffix "ei" $mem -}}
{{- printf "%sT" (trimSuffix "ei" $mem | atoi | mul 1024 1024 | toString) -}}
{{- else if hasSuffix "ti" $mem -}}
{{- printf "%sT" (1000 | div (trimSuffix "ti" $mem | atoi | mul 1024) | toString) -}}
{{- else if hasSuffix "gi" $mem -}}
{{- printf "%sG" (1000 | div (trimSuffix "gi" $mem | atoi | mul 1024) | toString) -}}
{{- else if hasSuffix "mi" $mem -}}
{{- printf "%sM" (1000 | div (trimSuffix "mi" $mem | atoi | mul 1024) | toString) -}}
{{- else if hasSuffix "ki" $mem -}}
{{- printf "%sK" (1000 | div (trimSuffix "ki" $mem | atoi | mul 1024) | toString) -}}
{{- else -}}
{{- $mem -}}
{{- end -}}
{{- end -}}

{{/*
This is a configuration block for a fluentd tail input plugin to support glob multiline format.
Since it will be used in multiple places, make it a template.
*/}}
{{- define "splunk-kubernetes-logging.tail-glog-multiline" -}}
multiline_flush_interval 5s
<parse>
  @type multiline
  format_firstline /^\w\d{4}/
  format1 /^(?<log>\w(?<time>\d{4} [^\s]*)\s+.*)/
  time_key time
  time_type string
  time_format %m%d %H:%M:%S.%N
</parse>
{{- end -}}

{{/*
This is a fluentd configuration block that shared by all journald sources.
*/}}
{{- define "splunk-kubernetes-logging.common-journald-source-conf" -}}
@type systemd
path  {{ .Values.journalLogPath | default "/run/log/journal" | quote }}
read_from_head true
<storage>
  @type local
  persistent true
</storage>
<entry>
  field_map {"MESSAGE": "log", "_SYSTEMD_UNIT": "source"}
  field_map_strict true
</entry>
{{- end -}}