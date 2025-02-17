CILIUM_SRC ?= $(HOME)/git/gopath/src/github.com/cilium/cilium-enterprise
CILIUM_HELM_CHART ?= $(CILIUM_SRC)/install/kubernetes/cilium
CILIUM_AGENT_LABEL ?= app.kubernetes.io/name=cilium-agent
CILIUM_OPERATOR_LABEL ?= app.kubernetes.io/name=cilium-operator

IPSEC_KEY = d8f55613436e6aeb1af8ebf1079bcd48b2af38cb
IPSEC_KEY_LITERAL = 3+ rfc4106(gcm(aes)) $(IPSEC_KEY) 128

.PHONY: install

deploy:
	kind create cluster --config ./cluster.yaml
	kubectl taint nodes cilium-testing-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

destroy:
	kind delete cluster --name cilium-testing

.ONESHELL:
install:
	export DOCKER_IMAGE_TAG="local"
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image
	cd -

	kind load --name cilium-testing docker-image quay.io/cilium/operator-generic:local
	kind load --name cilium-testing docker-image quay.io/cilium/cilium-dev:local
	helm -n kube-system install cilium $(CILIUM_HELM_CHART) -f values.yaml

install-ipsec-keys:
	  kubectl create -n kube-system secret generic cilium-ipsec-keys --from-literal=keys="$(IPSEC_KEY_LITERAL)"

.ONESHELL:
bounce:
	export DOCKER_IMAGE_TAG="local"
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image
	kind load --name cilium-testing docker-image quay.io/cilium/operator-generic:local
	kind load --name cilium-testing docker-image quay.io/cilium/cilium-dev:local

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

	kind load --name cilium-testing docker-image quay.io/cilium/operator-generic:local
	kind load --name cilium-testing docker-image quay.io/cilium/cilium-dev:local
	helm -n kube-system install cilium $(CILIUM_HELM_CHART) -f values.yaml

.ONESHELL:
bounce-debug:
	export DOCKER_IMAGE_TAG="local"
	export NOSTRIP=1
	export NOOPT=1
	export DEBUG_HOLD=true
	cd $(CILIUM_SRC)
	make docker-operator-generic-image
	make dev-docker-image-debug
	kind load --name cilium-testing docker-image quay.io/cilium/operator-generic:local
	kind load --name cilium-testing docker-image quay.io/cilium/cilium-dev:local

bounce-agents:
	kubectl --namespace=kube-system delete pod -l $(CILIUM_AGENT_LABEL)

bounce-operator:
	kubectl --namespace=kube-system delete pod -l $(CILIUM_OPERATOR_LABEL)

update-values:
	helm -n kube-system upgrade cilium $(CILIUM_HELM_CHART) -f values.yaml

echo-service:
	kubectl apply -f "./migrations-svc-deployment.yaml"

test-deployment:
	kubectl apply -f "./test-deployment.yaml"

reinstall:
	helm -n kube-system uninstall cilium
	helm -n kube-system install cilium $(CILIUM_HELM_CHART) -f values.yaml
