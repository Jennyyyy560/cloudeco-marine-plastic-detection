CloudEco — Plastic in River Detection API
A scalable machine-learning inference service built with FastAPI, containerised with Docker,
and orchestrated on a 3-node Kubernetes cluster (GCP). Detects plastic waste in river images using a pre-trained YOLOv8 model.

Live URL:http://34.126.192.147:30080
The NodePort service allows external traffic to reach the application through any node IP, regardless of where the pods are actually running.
Interactive API docs: http://34.126.192.147:30080/docs

1. Build and Push Docker Image
The Dockerfile uses a multi-stage build to minimise the final image size, and runs the container as a non-root user for enhanced security compliance.

# Build the image
docker build -t yzha1437/cloudeco:latest .

# Push to Docker Hub
docker login
docker push yzha1437/cloudeco:latest

For cross-platform build：
docker buildx build --platform linux/amd64 -t yzha1437/cloudeco:latest --push .

2. Provision GCP VMs (Terraform IaC)
Terraform provisions the 3 GCP VM instances (1 master + 2 workers) and the required firewall rules.

cd terraform

# Initialise Terraform (downloads GCP provider)
terraform init

# Authenticate with GCP
gcloud auth application-default login

# Preview resources to be created
terraform plan

# Create the VMs and firewall rules
terraform apply

3. Provision Kubernetes Cluster (Ansible IaC)
Run the playbooks in order to install and configure Kubernetes across all nodes:

cd ansible-k8s

# Run all playbooks in order:
ansible-playbook -i k8s-hosts.ini _users.yaml
ansible-playbook -i k8s-hosts.ini _prepare.yaml
ansible-playbook -i k8s-hosts.ini _install_k8s.yaml
ansible-playbook -i k8s-hosts.ini _create_master.yaml
ansible-playbook -i k8s-hosts.ini _join_workers.yaml

SSH into master node， then verify cluster is ready :

ssh -i ~/monash/FIT5225/CloudEco/key/oracle_k8s zhangyanll@34.129.101.167
# Veritify cluster
kubectl get nodes

4. Deploy Application to Kubernetes

# Apply both manifests from the CloudEco
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Verify pods are running
kubectl get pods
kubectl get svc

The API is now accessible at:

http://34.126.192.147:30080

5. API Endpoints

POST /api/predict:
Request:
{
  "uuid": "string",
  "image": "string"
}
Response:
{
  "uuid": "string",
  "count": 0,
  "detections": ["string"],
  "boxes": [
    {
      "x": 0,
      "y": 0,
      "width": 0,
      "height": 0,
      "probability": 0
    }
  ],
  "speed_preprocess_ms": 0,
  "speed_inference_ms": 0,
  "speed_postprocess_ms": 0
}

POST /api/annotate：
Request:
{
  "uuid": "string",
  "image": "string"
}
Response:
{
  "uuid": "string",
  "annotated_image": "string"
}

6. Load Testing with Locust

# Install Locust
pip install locust

# Run from the CloudEco/ directory (test_image.jpg must be present)
locust -f locustfile.py --host http://34.126.192.147:30080

Open http://localhost:8089 to control the test.

Scale pods for each benchmark:
kubectl scale deployment cloudeco --replicas=1
kubectl scale deployment cloudeco --replicas=2
kubectl scale deployment cloudeco --replicas=4
kubectl scale deployment cloudeco --replicas=8

