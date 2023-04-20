{{- /*

  Loads all script files into the "/scripts" mount point.

*/ -}}

{{- define "load_scripts" -}}
  {{- $prefix := index . 1 -}}
  {{- with index . 0 -}}
- name: load-scripts
  image: {{ .Values.images.bash }}
  workingDir: /scripts
  script: |
    set -e
  {{- range $path, $content := .Files.Glob "scripts/*.sh" }}
    {{- $name := trimPrefix "scripts/" $path }}
    {{- if or ( hasPrefix $prefix $name ) ( hasPrefix "common" $name ) }}
    printf '%s' "{{ $content | toString | b64enc }}" |base64 -d >{{ $name }}
    {{- end }}
  {{- end }}
    chmod +x /scripts/*.sh
  volumeMounts:
    - name: scripts-dir
      mountPath: /scripts
  {{- end -}}
{{- end -}}
