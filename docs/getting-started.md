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
│   └── kustomization.yaml              # Component selection and patches
├── values-hub.yaml                      # Hub Cluster Definition
├── values-global.yaml                   # Global Pattern Settings
├── common/                              # 📦 Validated Patterns Framework
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
- **Secret management**: Repository credentials for private Git repositories (if applicable)

---

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/validatedpatterns-sandbox/telco-hub-pattern.git
cd telco-hub-pattern
```

### 2. Configure Secrets (Optional)

If using private Git repositories for GitOps, configure repository access:

```bash
# Copy the secret template
cp values-secret.yaml.template values-secret.yaml

# Edit with your repository credentials
vim values-secret.yaml
```

Example configuration for SSH-based repository access:

```yaml
secrets:
  - name: ztp-repo
    targetNamespaces:
      - telco-hub-pattern
    labels:
      argocd.argoproj.io/secret-type: repository
    annotations:
      argocd.argoproj.io/sync-wave: "-40"
    type: Opaque
    fields:
      - name: url
        value: "git@your-git-server.com:namespace/repo.git"
      - name: insecure
        value: "false"
      - name: sshPrivateKey
        value: "-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
```

### 3. Configure Components

Edit `kustomize/overlays/telco-hub/kustomization.yaml` to enable required components:

```yaml
# =============================================================================
# Telco Hub Pattern - Kustomization Configuration
# =============================================================================

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  # Required: Advanced Cluster Management (uncomment to enable)
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/acm

  # Required: Topology Aware Lifecycle Manager (enabled by default)
  - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/talm

  # Workflow: GitOps ZTP Installation (uncomment if deploying clusters via ZTP)
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/gitops/ztp-installation

  # Optional Components (uncomment as needed):
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/lso
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/odf-internal  
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/optional/logging

  # Disconnected: Local Registry (uncomment for disconnected environments)
  # - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/registry

# Environment-specific patches (example for disconnected environments)
patches:
  - target:
      group: operators.coreos.com
      version: v1alpha1
      kind: Subscription
      name: openshift-topology-aware-lifecycle-manager-subscription
    patch: |-
      - op: replace
        path: "/spec/source"
        value: "redhat-operators"  # or "redhat-operators-disconnected"
```

### 4. Deploy the Pattern

```bash
# Deploy using the pattern framework (loads secrets if configured)
./pattern.sh make install
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
| `values-secret.yaml`                              | 🔐 Secret management            | Repository credentials and sensitive data    |
| `kustomize/overlays/telco-hub/kustomization.yaml` | 🎛️ Component selection & patches | Component enablement and environment customization |

### Secret Management

The pattern uses the validated patterns framework for secure secret management:

#### Secret Configuration

Secrets are defined in `values-secret.yaml` and injected via the pattern framework:

```yaml
# values-secret.yaml
secrets:
  - name: ztp-repo
    targetNamespaces:
      - telco-hub-pattern
    labels:
      argocd.argoproj.io/secret-type: repository
    annotations:
      argocd.argoproj.io/sync-wave: "-40"
    type: Opaque
    fields:
      - name: url
        value: "git@your-git-server.com:namespace/repo.git"
      - name: sshPrivateKey
        value: "-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
```

#### Secret Backend Configuration

Configure the secret backend in `values-global.yaml`:

```yaml
# values-global.yaml
global:
  secretStore:
    backend: none  # Use direct secret injection (no ESO)
```

#### Loading Secrets

```bash
# Load secrets into the cluster
./pattern.sh make load-secrets

# Or install pattern with secrets
./pattern.sh make install  # Automatically loads secrets
```

> **Security Note**: Never commit `values-secret.yaml` to Git. Use `values-secret.yaml.template` as a reference and keep actual secrets in a secure location.

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
-> ./pattern.sh help

Pattern: telco-hub-pattern

Usage:
  make <target>

Pattern tasks
  install                              installs the pattern and loads the secrets
  post-install                         Post-install tasks

Pattern Common Tasks
  help                                 This help message
  show                                 show the starting template without installing it
  preview-all                          (EXPERIMENTAL) Previews all applications on hub and managed clusters
  operator-deploy operator-upgrade     runs helm install
  uninstall                            runs helm uninstall
  load-secrets                         loads the secrets into the backend determined by values-global setting
  legacy-load-secrets                  loads the secrets into vault (only)
  secrets-backend-vault                Edits values files to use default Vault+ESO secrets config
  secrets-backend-kubernetes           Edits values file to use Kubernetes+ESO secrets config
  secrets-backend-none                 Edits values files to remove secrets manager + ESO
  load-iib                             CI target to install Index Image Bundles
  token-kubeconfig                     Create a local ~/.kube/config with password (not usually needed)

Validation Tasks
  validate-origin                      verify the git origin is available
  validate-cluster                     Do some cluster validations before installing
  validate-schema                      validates values files against schema in common/clustergroup
  validate-prereq                      verify pre-requisites
  argo-healthcheck                     Checks if all argo applications are synced

Test and Linters Tasks
  qe-tests                             Runs the tests that QE runs
  super-linter                         Runs super linter locally
```

### Day-2 Operations

#### Enabling Components

```bash
# Edit kustomization to enable components
vi kustomize/overlays/telco-hub/kustomization.yaml

# Uncomment desired component resources, for example:
# - https://github.com/openshift-kni/telco-reference//telco-hub/configuration/reference-crs/required/acm

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
# Watch ArgoCD applications
watch oc get applications.argoproj.io -n openshift-gitops

# Check telco-hub application status
oc describe applications.argoproj.io telco-hub -n telco-hub-pattern-hub

# View kustomize-generated resources
oc get all -l app.kubernetes.io/managed-by=ArgoCD
```

### Access ArgoCD UI

```bash
# Get ArgoCD route
echo "ArgoCD UI: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"

# Get admin password
oc extract secret/openshift-gitops-cluster -n telco-hub-pattern-hub --to=-
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

#### 4. Secret Management Issues

**Problem**: ArgoCD cannot access private repositories

```bash
# Check if secrets are loaded
oc get secrets -n telco-hub-pattern | grep ztp-repo

# Verify secret content
oc get secret ztp-repo -n telco-hub-pattern -o yaml
```

**Solution**: Ensure `values-secret.yaml` is properly configured and secrets are loaded via `./pattern.sh make load-secrets`

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
