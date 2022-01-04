{{- $nodeName := env "node.unique.name"}}
{{- range services }}
  {{- if in .Tags "nidito.http.enabled" }}
    {{- range service .Name }}
      {{- if not (in .Tags "nidito.http.public") }}
        {{- scratch.MapSet "services" .Name "local" }}
      {{- else }}
        {{- scratch.MapSet "services" .Name "public" }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- range $name, $data := (key "dns/static-entries" | parseJSON) }}
  {{- scratch.MapSet "services" $name "static" }}
{{- end }}
{{- range ls "cdn" }}
  {{- scratch.MapSet "services" .Key "cdn" }}
{{- end }}
{
  "node": "{{ $nodeName }}",
  "services": {{ scratch.Get "services" | explodeMap | toJSON }}
}
