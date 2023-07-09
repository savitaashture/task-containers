{{- /*

  Contains the results produced by buildah, should be part of a Tasks ".spec.results[]".

*/ -}}
{{- define "results_buildah" -}}
- name: IMAGE_URL
  description: |
    Fully qualified image name.
- name: IMAGE_DIGEST
  description: |
    Digest of the image just built.
{{- end -}}
