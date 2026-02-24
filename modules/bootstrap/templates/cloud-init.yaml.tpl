#cloud-config
ssh_pwauth: true
chpasswd:
  list:
    - ubuntu:${password}
  expire: False

ssh_authorized_keys:
  - ${ssh_public_key}

packages:
  - qemu-guest-agent
  - curl

runcmd:
  - systemctl enable --now qemu-guest-agent
  # Install RKE2
  - curl -sfL https://get.rke2.io | sh -
  - mkdir -p /etc/rancher/rke2
  - |
    cat <<EOF > /etc/rancher/rke2/config.yaml
    token: static-bootstrap-token-123
    EOF
  - |
    if [ "${node_index}" -eq "0" ]; then
      echo "server: https://127.0.0.1:9345" >> /etc/rancher/rke2/config.yaml
    else
      # Wait for the first node's Rancher/RKE2 to be ready via LB
      echo "server: https://${lb_ip}:9345" >> /etc/rancher/rke2/config.yaml
    fi
  - systemctl enable rke2-server.service
  - systemctl start rke2-server.service
  # Wait for RKE2 to be ready and config file to exist
  - until [ -f /etc/rancher/rke2/rke2.yaml ]; do sleep 5; done
  - export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
  - until /var/lib/rancher/rke2/bin/kubectl get nodes; do sleep 5; done
  # Install kubectl binary to /usr/local/bin
  - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  # Setup kubeconfig for the default user (ubuntu)
  - mkdir -p /home/ubuntu/.kube
  - cp /etc/rancher/rke2/rke2.yaml /home/ubuntu/.kube/config
  - chown ubuntu:ubuntu /home/ubuntu/.kube/config
  - chmod 600 /home/ubuntu/.kube/config
  # Install Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  # Add Rancher Helm Repo
  - /usr/local/bin/helm repo add rancher-stable https://releases.rancher.com/server-charts/stable --kubeconfig /etc/rancher/rke2/rke2.yaml
  - /usr/local/bin/helm repo update --kubeconfig /etc/rancher/rke2/rke2.yaml
  # Create Namespace
  - /var/lib/rancher/rke2/bin/kubectl create namespace cattle-system
  # Install Cert-Manager (Required for Rancher)
  - /var/lib/rancher/rke2/bin/kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
  # Robust wait for Cert-Manager components
  - /var/lib/rancher/rke2/bin/kubectl wait --for=condition=available --timeout=600s deployment/cert-manager -n cert-manager
  - /var/lib/rancher/rke2/bin/kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-webhook -n cert-manager
  - /var/lib/rancher/rke2/bin/kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-cainjector -n cert-manager
  # Install Rancher with a retry loop (Only on first node to avoid race conditions)
  - |
    if [ "${node_index}" -eq "0" ]; then
      for i in {1..10}; do
        /usr/local/bin/helm install rancher rancher-stable/rancher \
          --namespace cattle-system \
          --set hostname=${cluster_dns} \
          --set bootstrapPassword=${rancher_password} \
          --set replicas=${node_count} \
          --kubeconfig /etc/rancher/rke2/rke2.yaml && break || sleep 30
      done
    fi
