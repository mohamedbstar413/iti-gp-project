
This Terraform project provisions a secure, scalable, and GitOps-driven Kubernetes environment on **Amazon EKS** to host a full-stack web application. It includes networking, cluster management, CI/CD automation (via Jenkins and Argo CD), autoscaling, secrets management, and persistent storage.

---

## 🗂️ Project Structure

```
terraform/
├── main.tf                     # Root module: ties network + EKS
├── variables.tf                # Root variables (e.g., git_token)
├── outputs.tf                  # (Empty in current state)
│
├── network/                    # VPC, subnets, NAT, routing
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── eks/                        # EKS cluster and add-ons
│   ├── main.tf                 # EKS cluster + node group
│   ├── iam.tf                  # IAM roles for add-ons (LB, EBS, Jenkins, autoscaler)
│   ├── argocd.tf               # Argo CD + Applications (db, backend)
│   ├── argocd-image-updater.tf # Automated image updates
│   ├── cluster-autoscaler.tf   # Cluster autoscaler
│   ├── jenkins.tf              # Jenkins with PVC
│   ├── jenkins-manifests/      # PV/PVC YAMLs (hostPath – dev only)
│   ├── namespaces.tf           # Namespaces + ConfigMaps
│   ├── secretsmanager.tf       # AWS Secrets Manager + CSI Driver
│   ├── data.tf                 # Data sources (OIDC, policies, auth)
│   ├── variables.tf            # EKS-specific vars (region, passwords, etc.)
│   └── outputs.tf              # (Empty)
│
├── nginx.conf                  # Nginx config for frontend proxy
└── index.html                  # Static frontend placeholder
```

---

## 🚀 Core Features

### 1. **Infrastructure**
- **VPC**: `/16` CIDR with **3 public** and **3 private subnets** across AZs.
- **EKS Cluster**: Managed control plane (`iti-gp-cluster`).
- **Node Group**: `c7i-flex.large` instances, min=1 / max=3, in private subnets.
- **SSH Access**: Enabled via `new-key` (replace in production).

### 2. **GitOps & CI/CD**
- **Argo CD**: Installed via Helm (`server.service.type=LoadBalancer`).
  - Syncs `db-app` from `k8s/db` → `db-ns`.
  - Syncs `back-app` from `k8s/back` → `back-ns` with **auto-image updates**.
- **Argo CD Image Updater**: 
  - Monitors ECR image `910148268074.dkr.ecr.us-east-1.amazonaws.com/iti-gp-image`.
  - Uses GitHub PAT (`git_token`) to commit updated manifests.
- **Jenkins**: 
  - Deployed in `jenkins` namespace.
  - Uses IAM role to push/pull from ECR.

### 3. **Add-ons & Integrations**
- **Cluster Autoscaler**: Scales node group based on demand (uses broad IAM permissions – tighten in prod).
- **AWS Load Balancer Controller**: Role created for `ingress-nginx` (not yet deployed).
- **EBS CSI Driver**: Enables dynamic persistent volumes (role created).
- **Secrets Store CSI Driver**: Syncs AWS Secrets Manager secrets (`iti_gp_db_secret`) to Kubernetes `Opaque` secrets in `db-ns` and `back-ns`.

### 4. **Security**
- **IRSA (IAM Roles for Service Accounts)**: Used for:
  - Argo CD Image Updater
  - Cluster Autoscaler
  - Jenkins
  - EBS CSI Driver
  - Secrets CSI Provider
- **Secrets**: 
  - Database credentials stored in AWS Secrets Manager.
  - Git token passed via Terraform variable (use secure backend like SSM or Vault).

