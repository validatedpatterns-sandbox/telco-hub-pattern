# ACM (Advanced Cluster Management) Chart

This Helm chart configures Advanced Cluster Management for the telco hub pattern using ArgoCD Application.

## Overview

The ACM chart creates an ArgoCD Application that manages the Advanced Cluster Management configuration referenced from the telco-hub configuration repository.

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    acm:
      enabled: true  # Set to false to disable ACM
```

### Kustomize Patches

You can customize the ACM configuration using kustomize patches:

```yaml
telcoHub:
  acm:
    kustomizePatches:
      # Configure ACM Subscription to match the desired configuration
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: open-cluster-management-subscription
        patch: |-
          - op: replace
            path: "/metadata/name"
            value: "advanced-cluster-management"
          - op: replace
            path: "/spec/source"
            value: "redhat-operators"
          - op: add
            path: "/spec/startingCSV"
            value: "advanced-cluster-management.v2.8.3"
```

## Values

| Key                               | Type   | Default                                                  | Description                             |
|-----------------------------------|--------|----------------------------------------------------------|-----------------------------------------|
| `telcoHub.components.acm.enabled` | bool   | `true`                                                   | Enable/disable ACM component            |
| `telcoHub.acm.kustomizePatches`   | list   | See values.yaml                                          | Kustomize patches for ACM configuration |
| `telcoHub.git.repoURL`            | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                      |
| `telcoHub.git.targetRevision`     | string | `"main"`                                                 | Git target revision                     |

## Default Configuration

The chart includes default patches for:

- Configuring ACM subscription name to `advanced-cluster-management`
- Using Red Hat operators catalog
- Setting specific CSV version (`advanced-cluster-management.v2.8.3`)

## Features

Advanced Cluster Management provides:

- Multi-cluster management capabilities
- Policy-based governance
- Application lifecycle management across clusters
- Observability and monitoring for multi-cluster environments
