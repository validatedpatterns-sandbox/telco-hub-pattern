# LSO (localStorage Operator) Chart

This Helm chart configures the localStorage Operator for the telco hub pattern using ArgoCD Application.

## Overview

The LSO chart creates an ArgoCD Application that manages the localStorage Operator configuration referenced from the telco-hub configuration repository.

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    lso:
      enabled: true  # Set to false to disable LSO
```

### Kustomize Patches

You can customize the LSO configuration using kustomize patches:

```yaml
telcoHub:
  lso:
    kustomizePatches:
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: local-storage-operator
        patch: |-
          - op: replace
            path: "/spec/source"
            value: "redhat-operators"
          - op: replace
            path: "/spec/channel"
            value: "stable"
```

## Values

| Key                               | Type   | Default                                                  | Description                                            |
|-----------------------------------|--------|----------------------------------------------------------|--------------------------------------------------------|
| `metadata.namespace`              | string | `"openshift-gitops"`                                     | Namespace where the ArgoCD Application will be created |
| `telcoHub.components.lso.enabled` | bool   | `true`                                                   | Enable/disable LSO component                           |
| `telcoHub.lso.kustomizePatches`   | list   | `[]`                                                     | Kustomize patches for LSO configuration                |
| `telcoHub.git.repoURL`            | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                                     |
| `telcoHub.git.targetRevision`     | string | `"main"`                                                 | Git target revision                                    |
