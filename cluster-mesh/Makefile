CILIUM_AGENT_LABEL ?= app.kubernetes.io/name=cilium-agent
CILIUM_OPERATOR_LABEL ?= app.kubernetes.io/name=cilium-operator

CILIUM_SRC_CLUSTER_1 ?= $(HOME)/git/gopath/src/github.com/cilium/cilium-enterprise
CILIUM_HELM_CHART_CLUSTER_1 ?= $(CILIUM_SRC_CLUSTER_1)/install/kubernetes/cilium

CILIUM_SRC_CLUSTER_2 ?= $(HOME)/git/gopath/src/github.com/cilium/cilium-enterprise
CILIUM_HELM_CHART_CLUSTER_2 ?= $(CILIUM_SRC_CLUSTER_2)/install/kubernetes/cilium

KUBECTL_CONTEXT_1 = kind-cilium-testing-cluster-1
KUBECTL_CONTEXT_2 = kind-cilium-testing-cluster-2

IPSEC_KEY = d8f55613436e6aeb1af8ebf1079bcd48b2af38cb
IPSEC_KEY_LITERAL = 3+ rfc4106(gcm(aes)) $(IPSEC_KEY) 128

.PHONY: install

# deploys both clusters for cluster-mesh testing
deploy:
	kind create cluster --config ./cluster_1.yaml
	kubectl --context $(KUBECTL_CONTEXT_1) taint nodes cilium-testing-cluster-1-control-plane node-role.kubernetes.io/control-plane:NoSchedule-
	kind create cluster --config ./cluster_2.yaml
	kubectl --context $(KUBECTL_CONTEXT_2) taint nodes cilium-testing-cluster-2-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

destroy:
	kind delete cluster --name cilium-testing-cluster-1
	kind delete cluster --name cilium-testing-cluster-2

.ONESHELL:
install:
	echo "Installing Cilium on Cluster 1..."
	export DOCKER_IMAGE_TAG="local_cluster_1"
	cd $(CILIUM_SRC_CLUSTER_1)
	make docker-operator-generic-image
	make dev-docker-image
	cd -

	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/operator-generic:local_cluster_1
	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/cilium-dev:local_cluster_1
	helm --kube-context $(KUBECTL_CONTEXT_1) -n kube-system install cilium $(CILIUM_HELM_CHART_CLUSTER_1) -f values_1.yaml

	echo "Installing Cilium on Cluster 2..."
	export DOCKER_IMAGE_TAG="local_cluster_2"
	cd $(CILIUM_SRC_CLUSTER_2)
	make docker-operator-generic-image
	make dev-docker-image
	cd -

	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/operator-generic:local_cluster_2
	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/cilium-dev:local_cluster_2
	helm --kube-context $(KUBECTL_CONTEXT_2) -n kube-system install cilium $(CILIUM_HELM_CHART_CLUSTER_2) -f values_2.yaml

	echo "Configuring clustermesh"
	cilium clustermesh enable --context kind-cilium-testing-cluster-1 --service-type=NodePort
	cilium clustermesh enable --context kind-cilium-testing-cluster-2 --service-type=NodePort
	cilium clustermesh status --context kind-cilium-testing-cluster-1 --wait
	cilium clustermesh status --context kind-cilium-testing-cluster-2 --wait

	cilium clustermesh connect --context kind-cilium-testing-cluster-1 --destination-context kind-cilium-testing-cluster-2
	cilium clustermesh status --context kind-cilium-testing-cluster-1 --wait

install-ipsec-keys:
	  kubectl --context $(KUBECTL_CONTEXT_1) create -n kube-system secret generic cilium-ipsec-keys --from-literal=keys="$(IPSEC_KEY_LITERAL)"
	  kubectl --context $(KUBECTL_CONTEXT_2) create -n kube-system secret generic cilium-ipsec-keys --from-literal=keys="$(IPSEC_KEY_LITERAL)"

.ONESHELL:
bounce-cluster-1:
	export DOCKER_IMAGE_TAG="local_cluster_1"
	cd $(CILIUM_SRC_CLUSTER_1)
	make docker-operator-generic-image
	make dev-docker-image
	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/operator-generic:local_cluster_1
	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/cilium-dev:local_cluster_1

.ONESHELL:
bounce-cluster-2:
	export DOCKER_IMAGE_TAG="local_cluster_2"
	cd $(CILIUM_SRC_CLUSTER_2)
	make docker-operator-generic-image
	make dev-docker-image
	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/operator-generic:local_cluster_2
	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/cilium-dev:local_cluster_2

.ONESHELL:
bounce-debug-cluster-1:
	export DOCKER_IMAGE_TAG="local_cluster_1"
	export NOSTRIP=1
	export NOOPT=1
	export DEBUG_HOLD=true
	cd $(CILIUM_SRC_CLUSTER_1)
	make docker-operator-generic-image
	make dev-docker-image-debug
	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/operator-generic:local_cluster_1
	kind load --name cilium-testing-cluster-1 docker-image quay.io/cilium/cilium-dev:local_cluster_1

.ONESHELL:
bounce-debug-cluster-2:
	export DOCKER_IMAGE_TAG="local_cluster_2"
	export NOSTRIP=1
	export NOOPT=1
	export DEBUG_HOLD=true
	cd $(CILIUM_SRC_CLUSTER_2)
	make docker-operator-generic-image
	make dev-docker-image-debug
	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/operator-generic:local_cluster_2
	kind load --name cilium-testing-cluster-2 docker-image quay.io/cilium/cilium-dev:local_cluster_2

bounce-agents-cluster-1:
	kubectl --context $(KUBECTL_CONTEXT_1) --namespace=kube-system delete pod -l $(CILIUM_AGENT_LABEL)

bounce-agents-cluster-2:
	kubectl --context $(KUBECTL_CONTEXT_2) --namespace=kube-system delete pod -l $(CILIUM_AGENT_LABEL)

update-values-cluster-1:
	helm --kube-context $(KUBECTL_CONTEXT_1) -n kube-system upgrade cilium $(CILIUM_HELM_CHART_CLUSTER_1) -f values_1.yaml

update-values-cluster-2:
	helm --kube-context $(KUBECTL_CONTEXT_2) -n kube-system upgrade cilium $(CILIUM_HELM_CHART_CLUSTER_2) -f values_2.yaml

bounce-operator-cluster-1:
	kubectl --context $(KUBECTL_CONTEXT_1) --namespace=kube-system delete pod -l $(CILIUM_OPERATOR_LABEL)

bounce-operator-cluster-2:
	kubectl --context $(KUBECTL_CONTEXT_2) --namespace=kube-system delete pod -l $(CILIUM_OPERATOR_LABEL)

test-deployment:
	# cluster 1 has the clients
	kubectl -n kube-system --context $(KUBECTL_CONTEXT_1) apply -f test-deployment-cluster-1.yaml
	# cluster 2 has the servers
	kubectl -n kube-system --context $(KUBECTL_CONTEXT_2) apply -f test-deployment-cluster-2.yaml
