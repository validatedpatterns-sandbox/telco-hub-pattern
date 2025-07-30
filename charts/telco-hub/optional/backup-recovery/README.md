# Backup and Recovery Chart

This Helm chart configures backup and recovery for the telco hub pattern using ArgoCD Application.

## Overview

The Backup and Recovery chart creates an ArgoCD Application that manages backup and recovery configuration referenced from the telco-hub configuration repository.

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    backupRecovery:
      enabled: true  # Set to false to disable backup and recovery
```

### Kustomize Patches

Currently no kustomize patches are configured, but you can add them when needed:

```yaml
telcoHub:
  backupRecovery:
    kustomizePatches:
      # Example patch structure (for future use):
      # - target:
      #     group: operators.coreos.com
      #     version: v1alpha1
      #     kind: Subscription
      #     name: backup-operator
      #   patch: |-
      #     - op: replace
      #       path: "/spec/source"
      #       value: "redhat-operators"
```

## Values

| Key                                          | Type   | Default                                                  | Description                                             |
|----------------------------------------------|--------|----------------------------------------------------------|---------------------------------------------------------|
| `telcoHub.components.backupRecovery.enabled` | bool   | `true`                                                   | Enable/disable backup and recovery component            |
| `telcoHub.backupRecovery.kustomizePatches`   | list   | `[]`                                                     | Kustomize patches for backup and recovery configuration |
| `telcoHub.git.repoURL`                       | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                                      |
| `telcoHub.git.targetRevision`                | string | `"main"`                                                 | Git target revision                                     |

## Features

The backup and recovery component provides:

- Automated backup solutions for telco hub configurations
- Recovery procedures and policies
- Integration with OpenShift backup operators
- Disaster recovery capabilities
