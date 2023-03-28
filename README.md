# task-containers

## Task: Skopeo-Copy

Skopeo is a command line tool for working with remote image registries. 
The copy command will take care of copying the image from internal.registry to production.registry. If your production registry requires credentials to login in order to push the image, skopeo can handle that as well.

### Steps to run the Task
- Add the `username` and `password` in the `templates/secret.yaml` for the source and destination repositories. 
- `$ kubectl apply -f template/secret.yaml`. This ensures a secret object `sc-secret` is created and a service account `sc-account` referencing to the secret is also created.
- Follow the below `taskrun.yaml` template to run the task. 
```
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: skopeo-copy-run
spec:
  serviceAccountName: sc-account
  taskRef:
    name: skopeo-copy
  params:
    - name: SOURCE_REGISTRY
      value: <>             # eg - docker.io
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
```
