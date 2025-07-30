# TALM Chart

This Helm chart configures TALM (Topology-Aware Lifecycle Manager) infrastructure for the telco hub pattern using ArgoCD.

## Overview

The TALM chart creates TALM infrastructure including:

- ArgoCD Application for TALM operator configuration
- Kustomize patch support for runtime customization
- Flexible sync policies for ArgoCD deployment

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    talm:
      enabled: true         # Enable TALM operator
```

### TALM Kustomize Patches

Customize TALM operator configuration:

```yaml
telcoHub:
  talm:
    kustomizePatches:
      # Customize TALM operator subscription
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: topology-aware-lifecycle-manager
        patch: |-
          - op: replace
            path: "/spec/source"
            value: "redhat-operators"
```

### Sync Policy

Customize ArgoCD sync behavior:

```yaml
telcoHub:
  argocd:
    syncPolicy:
      automated:
        allowEmpty: true
        prune: true
        selfHeal: true
```

## Values

| Key                                | Type   | Default                                                  | Description                              |
|------------------------------------|--------|----------------------------------------------------------|------------------------------------------|
| `telcoHub.components.talm.enabled` | bool   | `true`                                                   | Enable/disable TALM infrastructure       |
| `telcoHub.talm.kustomizePatches`   | list   | See values.yaml                                          | Kustomize patches for TALM configuration |
| `telcoHub.git.repoURL`             | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                       |
| `telcoHub.git.targetRevision`      | string | `"main"`                                                 | Git target revision                      |

## Features

The TALM chart provides:

- **TALM Configuration**: Deploys and configures TALM operator for cluster lifecycle management
- **Cluster Updates**: Orchestrates OpenShift cluster updates across edge environments
- **Policy Management**: Applies configuration policies to managed clusters  
- **Rollout Control**: Controls the rollout of updates across multiple clusters
- **Backup and Recovery**: Manages cluster backup and recovery operations
