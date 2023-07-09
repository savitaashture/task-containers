{{- /*

  Contains the common params declaration, to be embedded on a Task's ".spec.params[]".

*/ -}}
{{- define "params_common" -}}
- name: TLS_VERIFY
  type: string
  default: "true"
  description: |
    Sets the TLS verification flag, `true` is recommended.
- name: VERBOSE
  type: string
  default: "false"
  description:
    Turns on verbose logging, all commands executed will be printed out.
{{- end -}}
