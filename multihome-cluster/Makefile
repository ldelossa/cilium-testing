CILIUM_SRC ?= $(HOME)/git/gopath/src/github.com/cilium/cilium-enterprise
CILIUM_HELM_CHART ?= $(CILIUM_SRC)/install/kubernetes/cilium
CILIUM_AGENT_LABEL ?= app.kubernetes.io/name=cilium-agent
CILIUM_OPERATOR_LABEL ?= app.kubernetes.io/name=cilium-operator

CLUSTER_NAME ?= cilium-testing
SECONDARY_NETWORK ?= kind-secondary
SECONDARY_SUBNET ?= 192.168.200.0/24

IPSEC_KEY = d8f55613436e6aeb1af8ebf1079bcd48b2af38cb
IPSEC_KEY_LITERAL = 3+ rfc4106(gcm(aes)) $(IPSEC_KEY) 128

.PHONY: install

deploy:
	kind create cluster --config ./cluster.yaml
	kubectl taint nodes $(CLUSTER_NAME)-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

	docker network create --driver bridge --subnet $(SECONDARY_SUBNET) $(SECONDARY_NETWORK) || true
	docker network connect $(SECONDARY_NETWORK) $(CLUSTER_NAME)-control-plane
	docker network connect $(SECONDARY_NETWORK) $(CLUSTER_NAME)-worker
	docker network connect $(SECONDARY_NETWORK) $(CLUSTER_NAME)-worker2

	docker exec $(CLUSTER_NAME)-control-plane ip route add table 100 default dev eth1
	docker exec $(CLUSTER_NAME)-worker ip route add table 100 default dev eth1
	docker exec $(CLUSTER_NAME)-worker2 ip route add table 100 default dev eth1

destroy:
	kind delete cluster --name $(CLUSTER_NAME)
	docker network rm $(SECONDARY_NETWORK) || true

.ONESHELL:
install:
	export DOCKER_IMAGE_TAG="local"
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image
	cd -

	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/operator-generic:local
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/cilium-dev:local
	cilium install --chart-directory $(CILIUM_HELM_CHART) -f values.yaml

install-ipsec-keys:
	kubectl create -n kube-system secret generic cilium-ipsec-keys --from-literal=keys="$(IPSEC_KEY_LITERAL)"

install-ztunnel-secrets:
	../scripts/ztunnel-secrets.sh

.ONESHELL:
bounce:
	export DOCKER_IMAGE_TAG="local"
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/operator-generic:local
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/cilium-dev:local

.ONESHELL:
install-debug:
	export DOCKER_IMAGE_TAG="local"
	export NOSTRIP=1
	export NOOPT=1
	export DEBUG_HOLD=true
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image-debug
	cd -

	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/operator-generic:local
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/cilium-dev:local
	cilium install --chart-directory $(CILIUM_HELM_CHART) -f values.yaml

.ONESHELL:
bounce-debug:
	export DOCKER_IMAGE_TAG="local"
	export NOSTRIP=1
	export NOOPT=1
	export DEBUG_HOLD=true
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image-debug
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/operator-generic:local
	kind load --name $(CLUSTER_NAME) docker-image quay.io/cilium/cilium-dev:local

bounce-agents:
	kubectl --namespace=kube-system delete pod -l $(CILIUM_AGENT_LABEL)

bounce-operator:
	kubectl --namespace=kube-system delete pod -l $(CILIUM_OPERATOR_LABEL)

update-values:
	cilium upgrade --chart-directory $(CILIUM_HELM_CHART) -f values.yaml


echo-service:
	kubectl apply -f "./migrations-svc-deployment.yaml"

test-deployment:
	kubectl apply -f "./test-deployment.yaml"

reinstall:
	helm -n kube-system uninstall cilium
	helm -n kube-system install cilium $(CILIUM_HELM_CHART) -f values.yaml
