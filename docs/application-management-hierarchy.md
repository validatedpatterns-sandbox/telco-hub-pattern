# Application Management Hierarchy

This document explains the complete management hierarchy of ArgoCD applications in the Telco Hub Pattern and provides troubleshooting guidance for common label drift issues.

## Overview

The Telco Hub Pattern uses the [Validated Patterns framework](https://validatedpatterns.io/) which creates a multi-layered application management hierarchy. Understanding this hierarchy is crucial for troubleshooting ArgoCD sync issues and implementing proper `ignoreDifferences` configurations.

## Management Hierarchy

```yaml
┌─────────────────────────────────────┐
│ Patterns Operator                   │
│ (patterns-operator-controller-      │
│  manager pod in openshift-operators)│
└─────────────┬───────────────────────┘
              │ manages
              ▼
┌─────────────────────────────────────┐
│ Pattern CR                          │
│ Name: telco-hub-pattern             │
│ Namespace: openshift-operators      │
│ Kind: patterns.gitops.hybrid-cloud- │
│       patterns.io/v1alpha1          │
└─────────────┬───────────────────────┘
              │ creates/manages
              ▼
┌─────────────────────────────────────┐
│ telco-hub-pattern-hub Application   │
│ (Uses clustergroup Helm chart from  │
│  https://charts.validatedpatterns.io)│
└─────────────┬───────────────────────┘
              │ creates/manages
              ▼
┌─────────────────────────────────────┐
│ telco-hub Application               │
│ (In telco-hub-pattern-hub namespace)│
└─────────────┬───────────────────────┘
              │ creates/manages
              ▼
┌─────────────────────────────────────┐
│ hub-config Application              │
│ (And other child applications:      │
│  - clusters, policies, etc.)        │
└─────────────────────────────────────┘
```

## Component Details

### 1. Patterns Operator (Root Controller)

**Location**: Pod `patterns-operator-controller-manager-*` in `openshift-operators` namespace

**Purpose**:

- Kubernetes operator that implements the Validated Patterns framework
- Watches Pattern custom resources and creates corresponding ArgoCD applications
- Manages the lifecycle of pattern deployments

**Key Responsibilities**:

- Creates and manages the root ArgoCD application (`telco-hub-pattern-hub`)
- Handles pattern-level configuration and status reporting
- Integrates with the clustergroup Helm chart from the Validated Patterns repository

### 2. Pattern Custom Resource

**Resource**: `patterns.gitops.hybrid-cloud-patterns.io/v1alpha1`
**Name**: `telco-hub-pattern`
**Namespace**: `openshift-operators`

**Configuration**:

```yaml
spec:
  clusterGroupName: hub
  gitSpec:
    targetRepo: http://jumphost.inbound.vz.bos2.lab:3000/kni/telco-hub-pattern.git
    targetRevision: kustomize-approach
  multiSourceConfig:
    clusterGroupChartVersion: 0.9.*
    enabled: true
```

**Purpose**: Defines the overall pattern configuration including Git repository, branch, and cluster group settings.

### 3. Root Application (telco-hub-pattern-hub)

**Location**: ArgoCD Application in `openshift-gitops` namespace
**Managed by**: Patterns Operator (based on Pattern CR)

**Multi-Source Configuration**:

- **Source 1**: Pattern repository reference (`patternref`)
  - Repository: `http://jumphost.inbound.vz.bos2.lab:3000/kni/telco-hub-pattern.git`
  - Branch: `kustomize-approach`
  - Used for: Values files and pattern-specific configuration

- **Source 2**: Clustergroup Helm chart
  - Repository: `https://charts.validatedpatterns.io/`
  - Chart: `clustergroup`
  - Version: `0.9.*`
  - Used for: Common validated patterns infrastructure

**Value Files Hierarchy**:

```yaml
valueFiles:
  - $patternref/values-global.yaml
  - $patternref/values-hub.yaml
  - $patternref/values-BareMetal.yaml
  - $patternref/values-BareMetal-4.19.yaml
  - $patternref/values-BareMetal-hub.yaml
  - $patternref/values-4.19-hub.yaml
  - $patternref/values-hub.yaml
```

### 4. Child Applications

**telco-hub Application**:

- **Location**: `telco-hub-pattern-hub` namespace
- **Purpose**: Manages the kustomize-based telco-hub deployment
- **Source**: `kustomize/telco-hub` path in the pattern repository

**hub-config Application**:

- **Location**: `openshift-gitops` namespace  
- **Purpose**: Deploys telco-reference configurations
- **Source**: `http://jumphost.inbound.vz.bos2.lab:3000/kni/telco-reference//telco-hub/configuration`

**Other Applications**: `clusters`, `policies`, etc.

## Common Issues and Troubleshooting

### Label Drift Issues

**Problem**: ArgoCD applications showing continuous sync due to label changes

**Symptoms**:

- Applications constantly show `OutOfSync` status
- Frequent automated syncs in application history
- Specific labels changing between:
  - `argocd.argoproj.io/instance: telco-hub`
  - `app.kubernetes.io/instance: hub-config`

**Root Cause**:
ArgoCD automatically applies management labels to resources, but these can conflict with labels expected by the source configurations, causing continuous drift detection.

**Solution**: Apply `ignoreDifferences` configuration to the appropriate level in the hierarchy.

### Identifying the Correct Application for ignoreDifferences

**Rule**: Apply `ignoreDifferences` to the **parent application** that manages the resource experiencing label drift.

**Examples**:

1. **If `hub-config` application has label drift**:
   - Apply `ignoreDifferences` to `telco-hub-pattern-hub` (the parent)
   - Target: ArgoCD Applications specifically

2. **If resources within an application have label drift**:
   - Apply `ignoreDifferences` to the application managing those resources
   - Target: Specific resource types and label paths

### Example ignoreDifferences Configuration

For application-level label drift (like the `hub-config` issue):

```yaml
# In kustomize/telco-hub/kustomization.yaml
patches:
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: telco-hub-pattern-hub
      namespace: openshift-gitops
    patch: |-
      - op: add
        path: "/spec/ignoreDifferences"
        value:
          - group: "argoproj.io"
            kind: "Application"
            jsonPointers:
            - /metadata/labels/argocd.argoproj.io/instance
            - /metadata/labels/app.kubernetes.io/instance
```

## Diagnostic Commands

### View Application Hierarchy

```bash
# List all ArgoCD applications
oc get applications.argoproj.io -A

# Check Pattern CR status
oc get patterns.gitops.hybrid-cloud-patterns.io -A

# View root application details
oc get application.argoproj.io/telco-hub-pattern-hub -n openshift-gitops -o yaml
```

### Check Application Sync Status

```bash
# Check specific application sync status
oc describe application.argoproj.io/hub-config -n openshift-gitops

# Monitor real-time sync events
oc get events -n openshift-gitops --sort-by='.lastTimestamp' | grep -i sync
```

### Verify Patterns Operator

```bash
# Check patterns operator status
oc get pods -n openshift-operators | grep pattern

# View operator logs
oc logs -n openshift-operators deployment/patterns-operator-controller-manager
```

## References

- [Validated Patterns Documentation](https://validatedpatterns.io/)
- [Clustergroup Chart Repository](https://github.com/validatedpatterns/clustergroup-chart)
- [ArgoCD ignoreDifferences Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/)

## Related Files

- [`kustomize/telco-hub/kustomization.yaml`](../kustomize/telco-hub/kustomization.yaml) - Contains patches for GitOps operator alignment and label drift fixes
- [`values-hub.yaml`](../values-hub.yaml) - Hub cluster configuration
- [`values-global.yaml`](../values-global.yaml) - Global pattern configuration
