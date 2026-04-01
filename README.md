# 🚀 CI/CD DevOps Project: Self-Hosted Kubernetes Cluster on Azure

Ce projet démontre la mise en place d'une infrastructure **End-to-End** automatisée pour le déploiement d'une application **Angular**. Contrairement aux solutions managées, ce projet repose sur un cluster **Kubernetes Self-Hosted**, offrant un contrôle total sur l'orchestration et la configuration système.

## 🏗️ Architecture du Projet

L'architecture est divisée en quatre piliers majeurs :

1.  **Infrastructure as Code (IaC) :** Provisionnement des ressources Azure (VNet, NSG, VMs) avec **Terraform**.
2.  **Configuration Management :** Préparation des nœuds (Containerd, Kubeadm) via **Ansible**.
3.  **Orchestration :** Cluster Kubernetes (1 Master, 1 Worker) avec réseau **Calico**.
4.  **CI/CD Pipeline :** Automatisation complète avec **Azure DevOps** (Build Docker & Deploy K8s).

---

## 🛠️ Stack Technique

| Domaine | Technologies |
| :--- | :--- |
| **Cloud** | Microsoft Azure |
| **IaC** | Terraform |
| **Configuration** | Ansible |
| **Orchestration** | Kubernetes (v1.28+), Helm |
| **CI/CD** | Azure Pipelines, Docker Hub |
| **App Web** | Angular 6+ |
| **Monitoring** | Prometheus, Grafana |

---

## 🚀 Workflow de Déploiement

### 1. Provisionnement (Terraform)
Le déploiement commence par la création de l'infrastructure réseau et des machines virtuelles. Le **Network Security Group** est configuré pour autoriser le trafic SSH, l'API Kubernetes et les ports applicatifs (**NodePort**).

### 2. Initialisation du Cluster
Ansible utilise un **inventaire dynamique Azure** pour configurer les VMs. 
* Installation du runtime **Containerd**.
* Initialisation du Control Plane via `kubeadm`.
* Jonction du nœud Worker au cluster.

### 3. Pipeline CI/CD
La pipeline Azure DevOps se déclenche à chaque commit sur la branche `master` :
* **Build :** Création de l'image Docker de l'application Angular.
* **Push :** Envoi de l'image vers Docker Hub avec un tag unique (`BuildId`).
* **Deploy :** Mise à jour des manifests Kubernetes (`deployment.yml`, `service.yml`) sur le cluster.

### 4. Observabilité
Une stack de monitoring (**kube-prometheus-stack**) est déployée via Helm pour surveiller la santé des nœuds et des Pods en temps réel via des dashboards **Grafana**.

---

## 🛠️ Installation Rapide

```bash
# 1. Provisionner l'infrastructure
cd terraform/
terraform init && terraform apply

# 2. Configurer les nœuds avec Ansible
cd ../ansible/
ansible-playbook -i my_azure_rm.yml k8s-setup.yml

# 3. Accéder à l'application
http://<MASTER_PUBLIC_IP>:<NODEPORT>
```
