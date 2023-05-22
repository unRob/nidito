{{- range secrets "nidito/service/event-gateway/listener" -}}
  {{- $name := . -}}
  {{- with secret (printf "nidito/service/event-gateway/listener/%s" $name) -}}
    {{- scratch.MapSet "listeners" $name .Data -}}
  {{- end -}}
{{- end -}}
{{ scratch.Get "listeners" | explodeMap | toJSON }}
