# GitOps Chart

This Helm chart configures GitOps infrastructure for the telco hub pattern using ArgoCD.

## Overview

The GitOps chart creates the essential GitOps infrastructure, including:

- AppProject for resource management
- ArgoCD Application for GitOps operator configuration
- Optional ZTP Installation Application for cluster installation workflows

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    gitops:
      enabled: true         # Enable GitOps infrastructure
    ztpInstallation:
      enabled: true         # Enable ZTP installation workflow
```

### GitOps Kustomize Patches

Customize ArgoCD and GitOps operator configuration:

```yaml
telcoHub:
  argocd:
    kustomizePatches:
      # Customize the hub-config Application to point to your telco-hub configuration
      - target:
          group: argoproj.io
          version: v1alpha1
          kind: Application
          name: hub-config
        patch: |-
          - op: replace
            path: "/spec/source"
            value:
              path: "telco-hub/"
              repoURL: "http://jumphost.inbound.lab:3000/kni/telco-reference.git"
              targetRevision: "add-telco-hub-pattern-bos2"

      # Ensure the GitOps operator uses Red Hat catalog
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: openshift-gitops-operator
        patch: |-
          - op: replace
            path: "/spec/source"
            value: "redhat-operators"
```

### ZTP Installation Patches

Configure ZTP workflow for cluster and policy management:

```yaml
telcoHub:
  ztpInstallation:
    kustomizePatches:
      # Configure clusters Application
      - target:
          group: argoproj.io
          version: v1alpha1
          kind: Application
          name: clusters
        patch: |-
          - op: replace
            path: "/spec/source/path"
            value: "clusters"
          - op: replace
            path: "/spec/source/repoURL"
            value: "http://jumphost.inbound.lab:3000/kni/faredge-ztp.git"
          - op: remove
            path: "/spec/syncPolicy"

      # Configure policies Application
      - target:
          group: argoproj.io
          version: v1alpha1
          kind: Application
          name: policies
        patch: |-
          - op: replace
            path: "/spec/source/path"
            value: "site-policies"
          - op: replace
            path: "/spec/source/repoURL"
            value: "http://jumphost.inbound.lab:3000/kni/faredge-ztp.git"
```

## Values

| Key                                           | Type   | Default                                                  | Description                                |
|-----------------------------------------------|--------|----------------------------------------------------------|--------------------------------------------|
| `telcoHub.components.gitops.enabled`          | bool   | `true`                                                   | Enable/disable GitOps infrastructure       |
| `telcoHub.components.ztpInstallation.enabled` | bool   | `true`                                                   | Enable/disable ZTP installation workflow   |
| `telcoHub.argocd.kustomizePatches`            | list   | See values.yaml                                          | Kustomize patches for GitOps configuration |
| `telcoHub.ztpInstallation.kustomizePatches`   | list   | See values.yaml                                          | Kustomize patches for ZTP workflow         |
| `telcoHub.git.repoURL`                        | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                         |
| `telcoHub.git.targetRevision`                 | string | `"main"`                                                 | Git target revision                        |

## Features

The GitOps chart provides:

- **AppProject**: Manages resource access and repositories for telco-hub applications
- **GitOps Configuration**: Deploys and configures ArgoCD and GitOps operators
- **ZTP Workflow**: Optional Zero Touch Provisioning for automated cluster installation
- **Repository Management**: Configures applications to point to your specific Git repositories
