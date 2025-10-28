# Telco Hub Pattern - Disconnected Deployment Guide

> **Image mirroring procedure for deploying the Telco Hub Pattern in air-gapped and disconnected network environments.**

[![OpenShift](https://img.shields.io/badge/OpenShift-4.14+-red?logo=redhat)](https://www.redhat.com/en/technologies/cloud-computing/openshift)
[![Validated Patterns](https://img.shields.io/badge/Validated-Patterns-blue)](https://validatedpatterns.io/)
[![Air-Gapped](https://img.shields.io/badge/Air--Gapped-Supported-green)](https://validatedpatterns.io/blog/2024-10-12-disconnected/)

---

## 📖 Table of Contents

- [Image Mirroring](#image-mirroring)
- [Configure Prerequisites](#configure-prerequisites)
- [Apply Prerequisites](#apply-prerequisites)

---

## Image Mirroring

Mirror all required container images and operator catalogs to your disconnected registry.

### Use Telco Hub ImageSet Configuration

The repository includes an [imageset-config.yaml](../kustomize/air-gapped/imageset-config.yaml) configuration optimized for telco workloads:

#### ImageSet Configuration Details

```yaml
# kustomize/air-gapped/imageset-config.yaml highlights:
mirror:
  platform:
    channels:
    - name: stable-4.19                       # OpenShift 4.19 platform
      type: ocp

  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    targetCatalog: openshift-marketplace/redhat-operators-disconnected
    packages:
    - name: advanced-cluster-management       # ACM 2.14
    - name: multicluster-engine               # MCE 2.9
    - name: openshift-gitops-operator         # GitOps 1.17
    - name: topology-aware-lifecycle-manager  # TALM
    - name: local-storage-operator            # LSO
    - name: odf-operator                      # ODF 4.19
    # ... additional ODF operators
  - catalog: registry.redhat.io/redhat/community-operator-index:v4.19
    targetCatalog: openshift-marketplace/community-operators-disconnected
    packages:
    - name: patterns-operator                 # Validated Patterns

  additionalImages:
  - name: registry.redhat.io/ubi8/ubi:latest
  - name: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.19
  - name: registry.redhat.io/rhacm2/multicluster-operators-subscription-rhel9:2.14.0-1
  - name: registry.redhat.io/rhel8/support-tools:latest
  # Validated Patterns framework images
  - name: registry.redhat.io/ubi9/ubi-minimal:latest
  - name: quay.io/hybridcloudpatterns/imperative-container:v1
```

### Mirror Images to Disconnected Registry

```bash
oc-mirror --config ./imageset-config.yaml \
          --workspace file://${OC_MIRROR_WORKDIR_PATH} --authfile ./pull_secret.json \
          docker://${LOCAL_REGISTRY_URL} --v2
```

Verify that the operation completes successfully and that IDMS, ITMS, and CatalogSource files are generated. Check the oc-mirror output for confirmation.

### Apply Generated Cluster Resources

```bash
oc apply -f ${OC_MIRROR_WORKDIR_PATH}/cluster-resources/cs-community-operators-disconnected-v4-19.yaml \
         -f ${OC_MIRROR_WORKDIR_PATH}/cluster-resources/cs-redhat-operators-disconnected-v4-19.yaml \
         -f ${OC_MIRROR_WORKDIR_PATH}/cluster-resources/itms-oc-mirror.yaml \
         -f ${OC_MIRROR_WORKDIR_PATH}/cluster-resources/idms-oc-mirror.yaml
```

> **IMPORTANT:** Update the [overlay/telco-hub/kustomization.yaml](../kustomize/overlays/telco-hub/kustomization.yaml) file with these generated artifacts before proceeding with pattern installation.

After applying these artifacts, cluster nodes will begin rolling out to apply the changes. This process may take several minutes. Monitor the rollout progress using the command below.

```bash
watch oc get no,mcp
```

---

## Configure Prerequisites

Configure the prerequisites for your disconnected environment. This updates the cluster proxy infrastructure with the CA certificate from your local registry.

> **NOTE:** This step is required because the pattern operator does not support custom CA certificates when pulling patterns from self-signed Git repositories over HTTPS.

```bash
vim ./kustomize/air-gapped/prerequisites/kustomization.yaml
```

---

## Apply Prerequisites

```bash
oc apply -k ./kustomize/air-gapped/prerequisites/
```

After applying these prerequisites, cluster nodes will begin rolling out to apply the changes. This process may take several minutes. Monitor the rollout progress using the command below.

```bash
watch oc get no,mcp
```

Once the prerequisites are applied, proceed with the standard pattern installation workflow as documented in the [Getting Started Guide](getting-started.md).
