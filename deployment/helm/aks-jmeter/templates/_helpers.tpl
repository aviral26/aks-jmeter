{{/*
Expand the name of the chart.
*/}}
{{- define "aks-jmeter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aks-jmeter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aks-jmeter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aks-jmeter.labels" -}}
helm.sh/chart: {{ include "aks-jmeter.chart" . }}
{{ include "aks-jmeter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common selector labels
*/}}
{{- define "aks-jmeter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aks-jmeter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common secrets
*/}}
{{- define "aks-jmeter.registry-secret-name" -}}
registry-secret
{{- end }}

{{/*
Disks
*/}}
{{- define "aks-jmeter.grafana-disk-name" -}}
grafana-disk
{{- end }}
{{- define "aks-jmeter.influxdb-disk-name" -}}
influxdb-disk
{{- end }}

{{/*
Reporter
*/}}
{{- define "aks-jmeter.reporter.name" -}}
reporter
{{- end }}
{{- define "aks-jmeter.reporter.influxdb-config-name" -}}
{{ include "aks-jmeter.reporter.name" .}}-influxdb-config
{{- end }}
{{- define "aks-jmeter.reporter.dashboard.name" -}}
{{ include "aks-jmeter.reporter.name" . }}-dashboard
{{- end }}
{{- define "aks-jmeter.reporter.influxdb.name" -}}
{{ include "aks-jmeter.reporter.name" . }}-influxdb
{{- end }}
{{- define "aks-jmeter.reporter.appLabels" -}}
app: {{ include "aks-jmeter.reporter.name" . }}
{{- end }}
{{- define "aks-jmeter.reporter.image" -}}
{{- printf "%s/%s:%s" .Values.reporter.image.namespacePrefix .Values.reporter.image.name .Values.reporter.image.tag }}
{{- end }}

{{/*
JMeter
*/}}
{{- define "aks-jmeter.jmeter.controller-name" -}}
jmeter-controller
{{- end }}
{{- define "aks-jmeter.jmeter.worker-name" -}}
jmeter-worker
{{- end }}
{{- define "aks-jmeter.jmeter.worker-modeLabels" -}}
jmeter_mode: worker
{{- end }}
{{- define "aks-jmeter.jmeter.controller-config-name" -}}
{{ include "aks-jmeter.jmeter.controller-name" .}}-config
{{- end }}
{{- define "aks-jmeter.jmeter.controller-modeLabels" -}}
jmeter_mode: controller
{{- end }}
{{- define "aks-jmeter.jmeter.controller-image" -}}
{{- printf "%s/%s:%s" .Values.jmeter.controller.image.namespacePrefix .Values.jmeter.controller.image.name .Values.jmeter.controller.image.tag }}
{{- end }}
{{- define "aks-jmeter.jmeter.worker-image" -}}
{{- printf "%s/%s:%s" .Values.jmeter.worker.image.namespacePrefix .Values.jmeter.worker.image.name .Values.jmeter.worker.image.tag }}
{{- end }}
