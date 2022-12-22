{{- define "base.ports" }}
{{- if . }}
{{- range $i, $v := . }}
- name: {{ $v.name }}
  containerPort: {{ $v.containerPort }}
  {{- if $v.hostPort }}
  hostPort: {{ $v.hostPort }}
  {{- end }}
  protocol: {{ $v.protocol | default "TCP" }}
{{- end }}
{{- end }}
{{- end }}