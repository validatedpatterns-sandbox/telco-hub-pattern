# TLS Authentication for Git Repositories

> **Guide for configuring TLS-based authentication for Git repositories in disconnected and enterprise environments.**

---

## Overview

This guide explains how to configure TLS certificate authentication for Git repositories used by the Telco Hub Pattern. TLS-based authentication is required in the following scenarios:

- **Disconnected environments**: The pattern operator does not support custom CA certificates in its API CR specification, causing TLS verification failures when cloning the telco-hub pattern repository from local Git servers with self-signed certificates.
- **Enterprise environments**: Institutional Git instances may not allow users to upload SSH public keys due to security policies, requiring TLS-based authentication instead of SSH.

---

## Configuration Points

TLS certificate configuration is required in three locations:

1. **Network Proxy Configuration** - Enables the pattern operator to clone the telco-hub pattern repository
2. **GitOps ArgoCD Configuration** - Enables ArgoCD applications to access Git repositories
3. **ZTP Installation Configuration** - Enables Zero Touch Provisioning workflows to access Git repositories

---

## 1. Network Proxy Configuration

The network proxy configuration allows the pattern operator to clone the telco-hub pattern repository from local Git servers with self-signed certificates during Day-0 installation.

### Network Proxy Location

`kustomize/air-gapped/prerequisites/kustomization.yaml`

### Network Proxy Configuration

Update the `cluster-proxy-config` ConfigMap patch to include your Git server's CA certificate:

```yaml
patches:
  # Add CA certificate bundle for self-signed GIT repositories in disconnected environments.
  # Required when the telco-hub pattern repo is hosted on local GIT servers with self-signed certificates
  # and without GIT authentication available. The pattern operator lack the ability of accepting
  # custom CAs currently, causing TLS verification failures during repo cloning.
  - target:
      group: ""
      version: v1
      kind: ConfigMap
      name: cluster-proxy-config
      namespace: openshift-config
    patch: |-
      - op: add
        path: /data/ca-bundle.crt
        value: |
          -----BEGIN CERTIFICATE-----
          MIIGcjCCBFqgAwIBAgIFICIE...
          -----END CERTIFICATE-----
```

### Apply Prerequisites

After updating the configuration, apply the prerequisites:

```bash
oc apply -k kustomize/air-gapped/prerequisites/
```

> **NOTE:** This step must be completed before installing the pattern. See the [Disconnected Deployment Guide](disconnected-deployment.md) for complete instructions.

---

## 2. GitOps ArgoCD TLS Configuration

Configure TLS certificates for ArgoCD applications to access Git repositories with self-signed certificates.

### GitOps TLS Location

`kustomize/overlays/telco-hub/kustomization.yaml`

### GitOps TLS Configuration

Update the `argocd-tls-certs-cm` ConfigMap patch in the GitOps section:

```yaml
patches:
  # Configure TLS certificates for Git repository access
  - target:
      version: v1
      kind: ConfigMap
      name: argocd-tls-certs-cm
    patch: |-
      - op: replace
        path: /data
        value:
          gitlab.cee.redhat.com: |
            -----BEGIN CERTIFICATE-----
            MIIGcjCCBFqgAwIBAgIFICIE...
            -----END CERTIFICATE-----
```

Replace `gitlab.cee.redhat.com` with your Git server hostname and include the full CA certificate chain.

---

## 3. ZTP Installation Configuration

When using the GitOps ZTP Installation component, configure the source repository URL to use HTTPS instead of SSH.

### ZTP Installation Location

`kustomize/overlays/telco-hub/kustomization.yaml`

### ZTP Installation Configuration

Uncomment and update the ZTP installation patches to use HTTPS URLs:

```yaml
patches:
  # ZTP Installation - Clusters Application
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: clusters
    patch: |-
      - op: replace
        path: "/metadata/namespace"
        value: "telco-hub-pattern"
      - op: replace
        path: "/spec/source/path"
        value: "ztp/gitops-subscriptions/argocd/example/siteconfig"
      - op: replace
        path: "/spec/source/repoURL"
        value: "https://github.com/openshift-kni/cnf-features-deploy"
      - op: replace
        path: "/spec/source/targetRevision"
        value: "master"
      - op: add
        path: "/spec/syncPolicy"
        value:
          automated: {}
```

> **IMPORTANT:** Ensure the `repoURL` uses the `https://` protocol. The TLS certificate for this repository must be configured in the GitOps ArgoCD TLS configuration (Section 2).

---

## Summary

1. **Network Proxy** (`kustomize/air-gapped/prerequisites/kustomization.yaml`) - Required for pattern operator to clone the telco-hub pattern repository
2. **GitOps TLS** (`kustomize/overlays/telco-hub/kustomization.yaml`) - Required for ArgoCD applications to access Git repositories
3. **ZTP Installation** (`kustomize/overlays/telco-hub/kustomization.yaml`) - Use HTTPS URLs for source repositories

All three configurations must be completed before deploying the pattern in disconnected or enterprise environments that require TLS authentication.
