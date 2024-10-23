mkdir -p /home/test/.kube
hstnumber='hostname | awk '{ print $1 }'| cut -c 11-12'
scp -rp root@k8s`eval $hostnu`-master:/etc/kubernetes/admin.conf /home/test/.kube/config
kubectl get node
