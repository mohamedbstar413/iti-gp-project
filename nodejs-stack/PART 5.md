
## 🔄 STEP 1: Rebuild & Redeploy from Scratch

### ▶️ Step 1.1: Rebuild the App Image
From your `jenkins_nodejs_example` directory:
```bash
cd jenkins_nodejs_example
docker build -t nodejs-app:local .
cd ../nodejs-stack  # back to Helm chart dir
```

### ▶️ Step 1.2: Recreate Kind Cluster
```bash
kind create cluster --name dev
```

### ▶️ Step 1.3: Load Image into Kind
```bash
kind load docker-image nodejs-app:local --name dev
```

### ▶️ Step 1.4: Install Helm Chart
```bash
helm install nodejs-stack . \
  --set app.image.tag=local \
  --set mysql.rootPassword="temp-root-pass" \
  --set mysql.password="temp-pass"
```

---

## 👀 STEP 2: Monitor & Verify

### 🔍 2.1 Watch Pods Become Ready
```bash
kubectl get pods -w
```
✅ Wait until you see:
```
mysql-xxxxx      1/1     Running   0      60s
redis-xxxxx      1/1     Running   0      60s
nodejs-app-xxxx  1/1     Running   0      45s
```

> ⏱️ May take 60–90 seconds total (MySQL init is slow).

### 🔍 2.2 Check Services
```bash
kubectl get svc
# Should show: mysql, redis, nodejs-app
```

### 🔍 2.3 Test App Endpoints
```bash
kubectl port-forward svc/nodejs-app 3000:3000 &
```

Then:
```bash
# Test homepage
curl -s http://localhost:3000
# → "Hi Abdelrahman"

# Test health
curl -s http://localhost:3000/health | jq .
# → {"status":"OK","uptime":...}

# Test ready
curl -s http://localhost:3000/ready | jq .
# → {"status":"READY"}
```

---
## 🧹 STEP 3: Full Cleanup

Run these commands to wipe **all resources**:

```bash
# 1. Uninstall Helm release (if exists)
helm uninstall nodejs-stack --namespace default 2>/dev/null

# 2. Delete persistent volumes (critical for MySQL/Redis)
kubectl delete pvc --all --namespace default 2>/dev/null

# 3. Delete leftover secrets or services (safe to run)
kubectl delete secret db-secrets --namespace default 2>/dev/null

# 4. Delete the Kind cluster (entire EKS-like environment)
kind delete cluster --name dev

# 5. Optional: Remove local Docker image (to force rebuild if needed)
docker rmi nodejs-app:local 2>/dev/null
```

## Screen Shots
![[Screenshot 2025-11-13 at 5.00.37 PM.png]]![[Screenshot 2025-11-13 at 5.00.46 PM.png]]