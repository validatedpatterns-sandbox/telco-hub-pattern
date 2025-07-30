# ODF (OpenShift Data Foundation) Chart

This Helm chart configures OpenShift Data Foundation for the telco hub pattern using ArgoCD Application.

## Overview

The ODF chart creates an ArgoCD Application that manages the OpenShift Data Foundation configuration referenced from the telco-hub configuration repository.

## Configuration

### Component Enablement

```yaml
telcoHub:
  components:
    odf:
      enabled: true  # Set to false to disable ODF
```

### Kustomize Patches

You can customize the ODF configuration using kustomize patches:

```yaml
telcoHub:
  odf:
    kustomizePatches:
      # Ensure the ODF operator uses Red Hat catalog
      - target:
          group: operators.coreos.com
          version: v1alpha1
          kind: Subscription
          name: odf-operator
        patch: |-
          - op: replace
            path: "/spec/source"
            value: "redhat-operators"

      # Configure StorageCluster for LVMS with 100Gi storage
      - target:
          group: ocs.openshift.io
          version: v1
          kind: StorageCluster
          name: ocs-storagecluster
        patch: |-
          - op: replace
            path: "/spec/storageDeviceSets/0/dataPVCTemplate/spec/resources/requests/storage"
            value: "100Gi"
          - op: replace
            path: "/spec/storageDeviceSets/0/dataPVCTemplate/spec/storageClassName"
            value: "lvms-vg1"
```

## Values

| Key                               | Type   | Default                                                  | Description                             |
|-----------------------------------|--------|----------------------------------------------------------|-----------------------------------------|
| `telcoHub.components.odf.enabled` | bool   | `true`                                                   | Enable/disable ODF component            |
| `telcoHub.odf.kustomizePatches`   | list   | See values.yaml                                          | Kustomize patches for ODF configuration |
| `telcoHub.git.repoURL`            | string | `"https://github.com/openshift-kni/telco-reference.git"` | Git repository URL                      |
| `telcoHub.git.targetRevision`     | string | `"main"`                                                 | Git target revision                     |

## Default Configuration

The chart includes default patches for:

- Using Red Hat operators catalog for ODF operator
- Configuring StorageCluster with LVMS backend (100Gi storage on lvms-vg1 storage class)
