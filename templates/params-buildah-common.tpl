{{- /*

  Contains the common buildah params declaration, to be embedded on a Task's ".spec.params[]".

*/ -}}
{{- define "params_buildah_common" -}}
- name: CONTEXT
  type: string
  default: "."
  description: |
    Path to the directory to use as context.
- name: STORAGE_DRIVER
  type: string
  default: vfs
  description: |
    Set buildah storage driver to reflect the currrent cluster node's
    settings.
- name: FORMAT
  description: The format of the built container, oci or docker
  default: "oci"
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
