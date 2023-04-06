# task-containers

## Task: Skopeo-Copy

Skopeo is a command line tool for working with remote image registries. 
The copy command will take care of copying the image from internal.registry to production.registry. If your production registry requires credentials to login in order to push the image, skopeo can handle that as well.

### Steps to run the Task
- Create a Kubernetes secrets containining credentials of the source and destination registries.  To create the Kubernetes secrets we can use the `kubectl create` command:
  ```
  kubectl create secret docker-registry <secret-name> \
          --docker-server="ghcr.io" \
          --docker-username="registry-username" \
          --docker-password="registry-password"
  ```
  Refer to [official Tekton documention](https://tekton.dev/docs/pipelines/auth/).

      
- We would need to pass the secret we just created to the service account. The Service Account ensures that the Kubernetes proxy the traffic of registry and automatically add the bearer tokens, so no further authentication will be required by the tasks using it. 
To add the secrets to the service account we can add the secret to the service account using the `kubectl edit` commmand:
  ```
  $ kubectl edit serviceaccount docker-serviceaccount
  ```
  An editor will open up. The user can simply add the secret in the `secrets key` as follow:
  ```
  secrets:
  - name: <secret-name>
  ```
  To learn more check the [reference documentation](https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_edit/).
- Follow the below `taskrun.yaml` template to run the task. 
  ```
  apiVersion: tekton.dev/v1beta1
  kind: TaskRun
  metadata:
    name: skopeo-copy-run
  spec:
    serviceAccountName: docker-serviceaccount
    taskRef:
      name: skopeo-copy
    params:
      - name: SOURCE_REGISTRY
        value: <>             # eg - docker.io, quay.io, ghcr.io
      - name: SOURCE_IMAGE
        value: <>             # username/imageName
      - name: SOURCE_TAG
        value: latest         # By default
      - name: DESTINATION_REGISTRY
        value: <>
      - name: DESTINATION_IMAGE
        value: <>
      - name: DESTINATION_TAG
        value: latest
      - name: TLS_VERIFY
        value: true
  ```
- To check how the full image url must be called for different hosts, refer to [this blog](https://www.redhat.com/en/blog/be-careful-when-pulling-images-short-name).
