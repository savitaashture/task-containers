{{- /*

  Contains the common buildah params declaration, to be embedded on a Task's ".spec.params[]".

*/ -}}
{{- define "params_buildah_common" -}}
- name: SUBDIRECTORY
  type: string
  default: "."
  description: |
    Relative subdirectory to the `source` Workspace for the build-context.
- name: STORAGE_DRIVER
  type: string
  default: overlay
  description: |
    Set buildah storage driver to reflect the currrent cluster node's
    settings.
- name: BUILD_EXTRA_ARGS
  type: string
  default: ""
  description: |
    Extra parameters passed for the build command when building images.
- name: PUSH_EXTRA_ARGS
  type: string
  default: ""
  description: |
    Extra parameters passed for the push command when pushing images.
- name: SKIP_PUSH
  default: "false"
  description: |
    Skip pushing the image to the container registry.
{{- end -}}
