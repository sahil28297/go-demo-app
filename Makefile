.PHONY: docker-build docker-tag-local docker-compose-up docker-compose-down install-vagrant create-vagrant-project deploy-kubernetes delete-kubernetes deploy-nomad

docker-build:
	cd docker && docker build -t zerodha-demo-app:latest .

docker-tag-local:
	docker tag zerodha-demo-app:latest zerodha-demo-app:local

docker-compose-up:
	cd docker && docker compose up -d

docker-compose-down:
	cd docker && docker compose down

install-vagrant:
	cd vagrant/bash-scripts && chmod +x install_vagrant.sh && bash install_vagrant.sh

create-vagrant-project:
	cd vagrant/bash-scripts && chmod +x create_vagrant_project.sh && bash create_vagrant_project.sh

deploy-kubernetes:
	cd kubernetes && kubectl apply -f namespace.yaml && kubectl apply -f resource-quota.yaml && kubectl apply -f redis-pvc.yaml && kubectl apply -f redis.yaml && cat nginx-pv.yaml | sed s+{{path}}+$$(pwd)+g | kubectl apply -f - && kubectl apply -f app.yaml && kubectl apply -f nginx-pvc.yaml && kubectl apply -f nginx.yaml && sudo kubectl port-forward service/nginx-service 80:80 -n demo-ops

delete-kubernetes:
	kubectl delete -f kubernetes

deploy-nomad:
	cd nomad && nomad namespace apply demo-ops && nomad job run demo-app.nomad.hcl
