# Logging Chart

This Helm chart configures logging infrastructure for the telco hub pattern using ArgoCD.

## Overview

The logging chart creates logging infrastructure including:

- ArgoCD Application for logging operator configuration
- Kustomize patch support for runtime customization
- Flexible sync policies for ArgoCD deployment

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    logging:
      enabled: true         # Enable logging operator
```

### Logging Kustomize Patches

Customize logging operator configuration:

```yaml
telcoHub:
  logging:
    kustomizePatches:
      # Customize logging operator subscription
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: cluster-logging
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

| Key                                   | Type   | Default                                                  | Description                                 |
|---------------------------------------|--------|----------------------------------------------------------|---------------------------------------------|
| `telcoHub.components.logging.enabled` | bool   | `true`                                                   | Enable/disable logging infrastructure       |
| `telcoHub.logging.kustomizePatches`   | list   | See values.yaml                                          | Kustomize patches for logging configuration |
| `telcoHub.git.repoURL`                | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                          |
| `telcoHub.git.targetRevision`         | string | `"main"`                                                 | Git target revision                         |

## Features

The logging chart provides:

- **Logging Configuration**: Deploys and configures cluster logging operator for centralized log management
- **Log Collection**: Collects logs from all cluster nodes and workloads
- **Log Forwarding**: Forwards logs to external log aggregation systems
- **Log Storage**: Manages local log storage and retention policies
- **Elasticsearch Integration**: Provides Elasticsearch backend for log indexing and search
