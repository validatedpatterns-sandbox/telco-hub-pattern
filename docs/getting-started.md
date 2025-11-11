# Getting Started with Telco Hub Pattern

> **Complete guide to deploy and configure the Telco Hub Pattern for GitOps-based telco-hub management using Red Hat OpenShift, Advanced Cluster Management (ACM), and Zero Touch Provisioning (ZTP).**

[![OpenShift](https://img.shields.io/badge/OpenShift-4.14+-red?logo=redhat)](https://www.redhat.com/en/technologies/cloud-computing/openshift)
[![Validated Patterns](https://img.shields.io/badge/Validated-Patterns-blue)](https://validatedpatterns.io/)
[![Helm](https://img.shields.io/badge/Helm-3.8+-blue?logo=helm)](https://helm.sh/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-green?logo=argo)](https://argoproj.github.io/cd/)

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture](#️-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#️-configuration)
- [Components](#-components)
- [Operations](#️-operations)
- [Troubleshooting](#-troubleshooting)
- [Next Steps](#-next-steps)

---

## 🎯 Overview

The **Telco Hub Pattern** delivers a production-ready, GitOps-based solution for deploying and managing telecommunications hub infrastructure. Built on the [Red Hat Validated Patterns](https://validatedpatterns.io/) framework, this pattern provides a modular approach to telco hub deployment with component-based enablement.

### Key Features

- **Kustomize-Based Architecture**: Direct consumption of [telco-reference](https://github.com/openshift-kni/telco-reference) base configurations with overlay customization
- **GitOps-Native**: Fully automated deployment via ArgoCD with integrated patterns framework
- **Lifecycle Management**: Integrated cluster management and upgrade capabilities via TALM
- **Component Selection**: Enable/disable telco components via kustomize resource declarations
- **Environment Customization**: Runtime patches without modifying upstream [reference-crs](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs) base configurations
- **Zero Touch Provisioning**: Automated cluster installation and configuration workflows

### Use Cases

- **Telco Edge Hub Management**: Deploy and manage multiple edge clusters from a central hub
- **Zero Touch Provisioning**: Automated cluster installation and configuration via ZTP workflow
- **Multi-Cluster Operations**: Centralized management of distributed telco infrastructure
- **GitOps Workflows**: Infrastructure-as-code with automated deployment and synchronization

### Rationale

The goal for this pattern is to:

- Use a GitOps approach to manage telco-hub configurations on OpenShift hub clusters
- Consume official telco-reference designs with environment-specific kustomize overlays
- Provide component selection with granular control over telco-hub components
- Support Zero Touch Provisioning workflows for automated cluster deployment
- Deliver a foundation for building GitOps-based telco applications and network functions

This pattern is designed specifically for telecommunications use cases and provides a hub cluster configuration optimized for telco workloads, network functions, and operational requirements with enterprise-grade lifecycle management.

---

## 🏗️ Architecture

### Pattern Structure

```bash
telco-hub-pattern/
├── kustomize/overlays/telco-hub/        # 🔧 Kustomize Overlay Configuration
│   └── kustomization.yaml               # Component selection and patches
├── kustomize/air-gapped/                # 🛡️ Disconnected (air-gapped) assets
│   ├── imageset-config.yaml             # Image mirroring (oc-mirror)
│   ├── prerequisites/                   # Cluster proxy, catalogs, CAs
│   │   └── kustomization.yaml
│   └── README.md                        # Disconnected deployment guide
├── values-hub.yaml                      # Hub Cluster Definition
├── values-global.yaml                   # Global Pattern Settings
└── docs/                                # Documentation

# Consumed Remote Resources (via kustomize):
# https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/
├── required/                            # 🔧 Essential Components
│   ├── acm/                             # Advanced Cluster Management
│   ├── gitops/                          # GitOps Operators & Configuration
│   ├── talm/                            # Topology Aware Lifecycle Manager
│   └── registry/                        # Local Registry (disconnected)
└── optional/                            # 🔌 Optional Components
    ├── lso/                             # Local Storage Operator
    ├── odf-internal/                    # OpenShift Data Foundation
    └── logging/                         # Cluster Logging Stack
```

### Design Principles

| Principle                 | Description                                                            | Benefit                                               |
|---------------------------|------------------------------------------------------------------------|-------------------------------------------------------|
| **Reference-Based**       | Direct consumption of official telco-reference configurations          | Always use validated, upstream telco designs         |
| **GitOps-Native**         | ArgoCD manages all deployments via validated patterns framework        | Automated, auditable infrastructure changes           |
| **Kustomize-First**       | Environment-specific overlays without modifying upstream configs       | Customize while maintaining upstream compatibility    |
| **Component Selection**   | Declarative component enablement via kustomize resources               | Granular control over telco-hub functionality        |

---

## ✅ Prerequisites

### System Requirements

#### OpenShift Cluster

- **Version**: OpenShift 4.14 or later
- **Size**: Compact cluster 3:0 nodes (minimum)
- **Storage**: 500GB+ available storage
- **Network**: internet connectivity for operator installations

> **Disconnected Environments**: For air-gapped deployments, see the [Disconnected Deployment Guide](disconnected-deployment.md).

#### Local Tools

```bash
# Required CLI tools
oc version              # OpenShift CLI 4.14+
git --version           # Git 2.x+

# Optional but recommended
jq --version            # JSON processing
yq --version            # YAML processing
```

#### Access Requirements

- **Cluster Admin**: Full administrative privileges on OpenShift cluster
- **Git repository** access for telco-reference configurations
- **oc CLI** tool configured and authenticated

---

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/validatedpatterns-sandbox/telco-hub-pattern.git
cd telco-hub-pattern
```

### 2. Configure Components

Edit `kustomize/overlays/telco-hub/kustomization.yaml` to review, enable, and customize components:

```yaml
# =============================================================================
# Telco Hub Pattern - Kustomization Configuration
# =============================================================================

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # Required: Local Registry
  # The Telco Hub Reference Design Specifications targets disconnected environments, hence this component is enabled by default.
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/registry

  # Required: Advanced Cluster Management (ACM)
  # The ACM telco-hub component requires a storage backend to support its observability functionality.
  # You NEED to configure a storage backend for the hub cluster along with ACM.
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/acm

  # Required: GitOps Operator
  # The telco-hub component creates the GitOps/ArgoCD instance used to manage spoke clusters. This instance
  # includes resource tuning for scalability and an ACM plugin for simplified creation of policies. The validated
  # pattern clustergroup chart does not make these tunings available, so a dedicated instance is created through
  # the `gitops` content. This dedicated instance has all the necessary tuning already included so the
  # `reference-crs/required/gitops` component does not need to be included. These `gitops` must be included
  # prior to the other components.
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/gitops
  - gitops/

  # Required: Topology Aware Lifecycle Manager (TALM)
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/talm

  # Workflow: GitOps ZTP Installation
  # Enable this telco-hub component if you deploy clusters via GitOps ZTP.
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/gitops/ztp-installation

  # Optional: Local Storage Operator (LSO)
  # Enable this telco-hub component if you use LSO to manage storage for ODF.
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/lso

  # Optional: Open Data Foundation (ODF)
  # Enable this telco-hub component if you use ODF as your storage backend.
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/odf-internal

  # Optional: Logging Operator
  # Enable this telco-hub component if you use the logging operator.
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/logging


# Environment-specific patches (example for disconnected environments)
patches:
  - target:
      group: operators.coreos.com
      version: v1alpha1
      kind: CatalogSource
      name: redhat-operators-disconnected
    patch: |-
      - op: replace
        path: /spec/image
        value: <registry.example.com:8443>/openshift-marketplace/redhat-operators-disconnected:v4.20
```

Commit and push telco-hub pattern overlay:

```bash
git commit ./kustomize/overlays/telco-hub/kustomization.yaml   # Configure telco-hub pattern overlay
git push
```

### 3. Install the pattern (loads secrets if configured)

```bash
# Install using the pattern framework
./pattern.sh make install
```

### 4. Update the pattern (does not load secrets)

```bash
# Update pattern during day2
./pattern.sh make operator-upgrade
```

### 5. Verify Deployment

```bash
# Check pattern deployment status
./pattern.sh make argo-healthcheck
```

**🎉 Your Telco Hub is now deploying via GitOps!**

---

## ⚙️ Configuration

### Configuration Hierarchy

The pattern uses a streamlined configuration system:

| File                                              | Purpose                         | When to Use                                  |
|---------------------------------------------------|---------------------------------|----------------------------------------------|
| `values-global.yaml`                              | 🌍 Global pattern settings      | Cross-environment pattern configuration      |
| `values-hub.yaml`                                 | 🏭 Hub cluster definition       | ArgoCD application and cluster configuration |
| `kustomize/overlays/telco-hub/kustomization.yaml` | 🎛️ Component selection & patches | Component enablement and environment customization |
| `kustomize/air-gapped/imageset-config.yaml`       | 🖼️ Image mirroring config      | Mirror required images and catalogs (disconnected) |
| `kustomize/air-gapped/prerequisites/kustomization.yaml` | 🛡️ Disconnected prerequisites | Apply proxy, CA, and catalog sources (disconnected) |

### Component Selection

Components are enabled by uncommenting resource declarations in the kustomization file:

#### Required Components

Essential for telco hub functionality:

```yaml
resources:
  # Advanced Cluster Management (uncomment to enable)
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/acm
  
  # Topology Aware Lifecycle Manager (enabled by default)
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/talm
```

#### ZTP Workflow

For automated cluster deployment:

```yaml
resources:
  # GitOps ZTP Installation (uncomment to enable)
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/gitops/ztp-installation
```

#### Optional Components

Enable based on requirements:

```yaml
resources:
  # Local Storage Operator
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/lso
  
  # OpenShift Data Foundation  
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/odf-internal
  
  # Cluster Logging
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/logging
```

### Environment Customization

Apply environment-specific patches without modifying upstream configurations:

```yaml
patches:
  # Example: Configure TALM operator for disconnected environments
  - target:
      group: operators.coreos.com
      version: v1alpha1
      kind: Subscription
      name: openshift-topology-aware-lifecycle-manager-subscription
    patch: |-
      - op: replace
        path: "/spec/source"
        value: "redhat-operators-disconnected"
  
  # Example: Customize storage classes for ODF
  - target:
      group: ocs.openshift.io
      version: v1
      kind: StorageCluster
      name: ocs-storagecluster
    patch: |-
      - op: replace
        path: "/spec/storageDeviceSets/0/dataPVCTemplate/spec/storageClassName"
        value: "localblock"
```

> **📘 REFERENCE:** For complete patch examples, see the [telco-reference example overlays](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/example-overlays-config) for each component.

---

## 📦 Components

### Component Reference

| Component            | Type     | Description                                              | Reference Configuration                                                                                                                                                     |
|----------------------|----------|----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Registry**         | Required | Local Registry for disconnected environments             | [telco-reference/required/registry](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/registry)                  |
| **ACM**              | Required | Advanced Cluster Management for multi-cluster operations | [telco-reference/required/acm](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/acm)                              |
| **GitOps**           | Required | ArgoCD operators and GitOps configuration                | [telco-reference/required/gitops](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/gitops)                        |
| **TALM**             | Required | Topology Aware Lifecycle Manager for cluster updates     | [telco-reference/required/talm](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/talm)                            |
| **ZTP Installation** | Workflow | Zero Touch Provisioning cluster installation workflow    | [telco-reference/required/gitops/ztp-installation](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/gitops/ztp-installation) |
| **LSO**              | Optional | LocalStorage Operator for node-local storage             | [telco-reference/optional/lso](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/optional/lso)                              |
| **ODF**              | Optional | OpenShift Data Foundation for persistent storage         | [telco-reference/optional/odf-internal](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/optional/odf-internal)            |
| **Logging**          | Optional | Cluster Logging Operator for log aggregation             | [telco-reference/optional/logging](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/optional/logging)                      |

### Component Dependencies

```mermaid
graph TD
    A[Kustomize Overlay] --> B[Telco-Reference CRs]
    B --> C[Registry]
    B --> D[ACM]
    B --> E[TALM]
    B --> F[ZTP Installation]
    D --> G[Managed Clusters]
    F --> G
    E --> H[Cluster Upgrades]
    
    I[Optional Components] --> J[LSO]
    I --> K[ODF]
    I --> L[Logging]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style I fill:#fff3e0
```

---

## 🛠️ Operations

### Available Commands

The pattern includes comprehensive management via the pattern framework:

```bash
-> ./pattern.sh make help

For a complete guide to these targets and the available overrides, please visit https://validatedpatterns.io/blog/2025-08-29-new-common-makefile-structure/

Usage:
  make <target>

Testing & Development Tasks
  argo-healthcheck                     Checks if all argo applications are synced
  validate-telco-reference             Validates telco-hub pattern against telco-reference CRs using cluster-compare
  super-linter                         Runs the super-linter locally
  validate-kustomize                   Validates kustomization build and YAML format
  help                                 Print this help message

Pattern Install Tasks
  show                                 Shows the template that would be applied by the `make install` target
  operator-deploy operator-upgrade     Installs/updates the pattern on a cluster (DOES NOT load secrets)
  install                              Installs the pattern onto a cluster (Loads secrets as well if configured)
  load-secrets                         Loads secrets onto the cluster (unless explicitly disabled in values-global.yaml)

Validation Tasks
  validate-prereq                      verify pre-requisites
  validate-origin                      verify the git origin is available
  validate-cluster                     Do some cluster validations before installing
```

### Day-2 Operations

#### Enabling Components

```bash
# Edit kustomization to enable components
vi kustomize/overlays/telco-hub/kustomization.yaml

# Uncomment desired component resources, for example:
# - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/logging

# Apply changes
./pattern.sh make operator-upgrade
```

#### Updating Environment Patches

```bash
# Update kustomize patches for your environment
vi kustomize/overlays/telco-hub/kustomization.yaml

# Add or modify patches section, for example:
# patches:
#   - target:
#       kind: Subscription
#       name: my-operator-subscription
#     patch: |-
#       - op: replace
#         path: "/spec/source"
#         value: "my-catalog-source"

# Apply configuration changes
./pattern.sh make operator-upgrade
```

#### Monitoring Deployment

```bash
# Check telco-hub application status
oc describe applications.argoproj.io telco-hub -n telco-hub-pattern-hub

# Check clusters and policies applications to view status of deployed managed clusters
oc describe applications.argoproj.io telco-hub -n telco-hub-pattern

# View all the ArgoCD applications managed by the pattern
./pattern.sh make argo-healthcheck
```

### Access ArgoCD UI

Retrieve the route for the `telco-hub` application:

```bash
# Get ArgoCD route
echo "ArgoCD UI: https://$(oc get route hub-gitops-server -n telco-hub-pattern-hub -o jsonpath='{.spec.host}')"

# Get admin password
oc extract secret/hub-gitops-cluster -n telco-hub-pattern-hub --to=-
```

Retrieve the route for the `clusters` and `policies` applications:

```bash
# Get ArgoCD route
echo "ArgoCD UI: https://$(oc get route telco-hub-gitops-server -n telco-hub-pattern -o jsonpath='{.spec.host}')"

# Get admin password
oc extract secret/telco-hub-gitops-cluster -n telco-hub-pattern --to=-
```

> **NOTE:** To access ArgoCD UI you can also use the nine box available in the Red Hat OpenShift Console.

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Component Sync Failures

**Problem**: ArgoCD applications showing sync errors

```bash
# Check application status
oc get applications.argoproj.io -n telco-hub-pattern-hub -o wide

# View detailed status
oc describe applications.argoproj.io <app-name> -n telco-hub-pattern-hub
```

**Solution**: Verify component configuration and kustomize patches

#### 2. Git Repository Access

**Problem**: ArgoCD cannot access telco-reference repository

```bash
# Check kustomize resource URLs
grep -r "github.com/openshift-kni/telco-reference" kustomize/overlays/telco-hub/kustomization.yaml
```

**Solution**: Verify telco-reference repository URLs are accessible and network connectivity is available

#### 3. Component Dependencies

**Problem**: Components failing due to missing dependencies

```bash
# Check operator status
oc get csv -A | grep -E "(acm|gitops|talm)"
```

**Solution**: Ensure required operators are installed and components are properly uncommented in kustomization.yaml

### Support Resources

- 📖 [Main Documentation](../README.md)
- 🔍 [Red Hat Validated Patterns](https://validatedpatterns.io/)
- 💬 [OpenShift GitOps Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest/html/understanding_openshift_gitops/about-redhat-openshift-gitops)

---

## 📚 Next Steps

### Immediate Actions

1. **Explore ArgoCD UI**: Familiarize yourself with the GitOps interface
2. **Review Component Status**: Ensure all enabled components are healthy
3. **Test Configuration Changes**: Make a small change and observe the sync process
4. **Setup Monitoring**: Configure alerts for pattern health

### Component Documentation

Official component documentation is available in the telco-reference repository:

- [ACM Configuration](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/acm)
- [GitOps Setup](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/gitops)  
- [TALM Management](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/required/talm)
- [Optional Components](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/reference-crs/optional)
- [Example Overlays](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub/configuration/example-overlays-config)

### Disconnected Environments

For air-gapped and disconnected network deployments:

- **[Disconnected Deployment Guide](disconnected-deployment.md)** — Complete guide for deploying in restricted environments

### External Resources

- [Red Hat Validated Patterns](https://validatedpatterns.io/learn)
- [OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest/html/understanding_openshift_gitops/about-redhat-openshift-gitops)
- [Advanced Cluster Management](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Zero Touch Provisioning](https://docs.openshift.com/container-platform/latest/scalability_and_performance/ztp_far_edge/ztp-deploying-far-edge-clusters-at-scale.html)

---

<div align="center">

**Ready to deploy your Telco Hub?**

[Report Issues](https://github.com/validatedpatterns-sandbox/telco-hub-pattern/issues) • [Main Documentation](../README.md)

---

## Complete Guide for Telco Hub Pattern

</div>
