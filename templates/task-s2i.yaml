---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: s2i
  labels:
    app.kubernetes.io/version: {{ .Chart.Version }}
{{- if .Values.annotations }}
  annotations:
  {{- .Values.annotations | toYaml | nindent 4 }}
{{- end }}
spec:
  description: |
    Builds the source code with s2i Golang builder.

  workspaces:
    - name: source
      optional: false
      description: |
        Application source code, the build context for S2I workflow.

  params:
    - name: IMAGE
      type: string
      description: |
        Fully qualified container image name to be built by s2i.
    - name: BUILDER_IMAGE
      type: string
      description: |
        Fully qualified s2i builder container image name.

{{- include "params_buildah_common" . | nindent 4 }}
{{- include "params_common" . | nindent 4 }}

  results:
{{- include "results_buildah" . | nindent 4 }}

  stepTemplate:
    env:
{{- $variables := list
      "params.IMAGE"
      "params.BUILDER_IMAGE"
      "params.SUBDIRECTORY"
      "params.STORAGE_DRIVER"
      "params.BUILD_EXTRA_ARGS"
      "params.PUSH_EXTRA_ARGS"
      "params.SKIP_PUSH"
      "params.TLS_VERIFY"
      "params.VERBOSE"
      "workspaces.source.bound"
      "workspaces.source.path"
      "results.IMAGE_URL.path"
      "results.IMAGE_DIGEST.path"
}}
{{- include "environment" ( list $variables ) | nindent 6 }}

  steps:
{{- include "load_scripts" ( list . "buildah-" "s2i-" ) | nindent 4 }}

    - name: s2i-generate
      image: {{ .Values.images.s2i }}
      workingDir: $(workspaces.source.path)
      command:
        - /scripts/s2i-generate.sh
      securityContext:
        runAsUser: 0
      volumeMounts:
        - name: scripts-dir
          mountPath: /scripts
        - name: s2i-generate-dir
          mountPath: /s2i-generate

    - name: s2i-build
      image: {{ .Values.images.buildah }}
      workingDir: /s2i-generate
      command:
        - /scripts/s2i-build.sh
      securityContext:
        privileged: true
      volumeMounts:
        - name: scripts-dir
          mountPath: /scripts
        - name: s2i-generate-dir
          mountPath: /s2i-generate

  volumes:
    - name: scripts-dir
      emptyDir: {}
    - name: s2i-generate-dir
      emptyDir: {}
