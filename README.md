# Zerodha Ops Task

## Description

This repo contains solutions to the tasks defined in `README-task.md` file.


### Pre-requisites

In order to run the solutions mentioned in this repo, one must have the following applications installed:
- Go
- Docker
- Docker Compose
- Vagrant
- Virtual Box
- Ansible
- Kubernetes
- Nomad


### Setting up the app.

In order to proceed with the solutions, first you'll need to compile the Go binary of the application.
- ```cd docker```
- ```make build```

This is a Go application which connects to Redis. The app increments a Redis `counter` (key `demo:requests`) on an incoming request at path `/`. It also requires two environment variables:
- `DEMO_APP_ADDR` default set as `:8080`, exposes the app at this port.
- `DEMO_REDIS_ADDR`, connects to redis (eg: `redis:6379`).

## Tasks

### - Create a `Dockerfile` for the app.

The solution to this task is defined in the `docker` folder of this repository

```
cd docker
```

#### Dockerfile Explanation.
- We begin our Dockerfile with the (optional) parser directive line used by BuildKit for file interpretation (version of syntax). We then tell Docker what base image we would like to use for our application, here we are using official Go image that already has all necessary tools and libraries to compile and run a Go application.
  ```
  # syntax=docker/dockerfile:1

  FROM golang:1.13
  ```
- We then set a Working Directory inside the image that we are building, this also instructs docker to set this as the default destination for all subsequent commands.
  ```
  WORKDIR /app
  ```
- Before we install the modules necessary to compile the Go application, we need to copy `go.mod` and `go.sum` files. After Copying the required files we run `go mod download`.
  ```
  COPY go.mod go.sum ./
  RUN go mod download
  ```
- The next thing we need to do is to copy our source code into the image.
  ```
  COPY main.go ./
  ```
- Next, we declare the Environment variables that will be used by our application
  ```
  ENV DEMO_APP_ADDR 8080
  ENV DEMO_REDIS_ADDR redis:6379
  ```
- Now, we would like to compile our application. This will output a binary called `zerodha-demo-app`.
  ```
  RUN CGO_ENABLED=0 go build -o /zerodha-demo-app -ldflags="-X 'main.version=${VERSION}'"
  ```
- We also expose the port that our Go application will listen to
  ```
  EXPOSE ${DEMO_APP_ADDR}
  ```
- Now, all that is left to do is to tell Docker what command to execute when our image is used to start a container. Here we execute our Go binary.
  ```
  CMD ["/zerodha-demo-app"]
  ```

#### Build the image.

Now that we've created our Dockerfile, let’s build an image from it.

```
docker build -t zerodha-demo-app:latest .
```

Docker image `zerodha-demo-app` with tag `latest` is created

<br>

***

***

### - Create a `docker-compose.yml` for the app.

The solution to this task is defined in the `docker` folder of this repository

```
cd docker
```

#### `docker-compose.yaml` explanation.

We've created a `docker-compose.yaml` file with 3 services:
- Redis
  ```
  redis:
    image: redis:latest
    container_name: redis
    volumes:
      - ./redis:/data
    ports:
      - "6379:6379"
  ```
  - Uses the latest Official Redis image
  - Defines the conatiner name as `redis`.
  - Mounts the local `redis` directory to `data` directory inside the container, this is used to persist data.
  - Forwards port `6379` of host to port `6379` of container.

- App
  ```
  app:
    image: zerodha-demo-app:latest
    container_name: app
    ports:
      - "8080:8080"
    environment:
      - DEMO_APP_ADDR=:8080
      - DEMO_REDIS_ADDR=redis:6379
    depends_on:
      - redis
  ```
  - Uses the image `zerodha-demo-app` with `latest` tag, local image will be used if you've executed the `docker build` command as detailed above.
  - Defines the container name as `app`.
  - Forwards port `8080` of host to port `8080` of container.
  - Uses two Environment Variables:
    - `DEMO_APP_ADDR` with default value as `:8080`.
    - `DEMO_REDIS_ADDR` with default value as `redis:6379`.
  - Declares the dependency on `redis` service, this service won't be created before `redis` service is created.
- Nginx
  ```
  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx-conf:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
  ```
  - Uses the latest Official Nginx image.
  - Defines the container name as `nginx`.
  - Forwards port `80` of host to port `80` of container and port `443` of host to port `443` of container.
  - Mounts two volumes:
    - `nginx/nginx-conf` of local to `/etc/nginx/conf.d` of container. This contains `default.conf` that will be used by nginx to set the configuration. The configuration listes to port `80`, port `443` and `localhost` and proxies the request to `http://app:8080/` which is the `app` service defined above. The nginx config also has ssl certificates defined for `zerodhademoapp.com` domain (example domain) which was generated using openssl.
      ```
      openssl req -x509 -nodes -days 365 -subj "/C=CA/ST=QC/O=Company, Inc./CN=zerodhademoapp.com" -addext "subjectAltName=DNS:zerodhademoapp.com" -newkey rsa:2048 -keyout zerodha-demo-app.key -out zerodha-demo-app.crt;
      ```
    - `nginx/ssl` of local to `/etc/nginx/ssl` of container. This fodler contains the ssl certificate and key generated by the `openssl` command mentioned above.


#### Run `docker.compose.yaml`.

```
docker compose up
```
Or to run it in detached mode (background)
```
docker compose up -d
```
Since we have the image built locally, we can also add `--pull never` to force docker compose to use local images.

Now to check if the application is running properly, go to your browser and enter the url `https://localhost` or `http://localhost`, you should get a page like
```
welcome to api. key count is: 1
```
<br>

***

***

### Write a bash script to set up a Vagrant box with Ubuntu.

The solution to this task is defined in the `vagrant/bash-scripts` folder of this repository
```
cd vagrant/bash-scripts
```

#### Install Brew, Vagrant and Virtual Box

- Install Homebrew if not already installed.
  ```
  if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  else
    echo "Homebrew is already installed."
  fi
  ```
  We check if brew is already installed by `command -v brew` and piping the output to `/dev/null` where the output is ignored by the shell. If there was no output, we install homebrew.

- Install Vagrant if not already installed.
  ```
  if ! command -v vagrant &>/dev/null; then
    echo "Vagrant is not installed. Installing..."
    brew install --cask vagrant
  else
    echo "Vagrant is already installed."
  fi
  ```
  Using the same logic as above we check if vagrant is installed by running `command -v vagrant` and if there's no output, we install vagrant using brew.

- Install Virtual Box is not already installed.
  ```
  if ! command -v VirtualBox &>/dev/null; then
    echo "VirtualBox is not installed. Installing..."
    brew tap homebrew/cask-versions
    brew install virtualbox-beta
  else
    echo "VirtualBox is already installed."
  fi
  ```
  Check if VirtualBox is installed, if not we install VirtualBox using brew.
  **Note:** I'm running M1 Mac (ARM64) laptop which does not support stable Virtualbox, hence using a beta version. If you're not on a ARM64 machine, you can use `brew install virtualbox`.

Run The script using bash
```
chmod +x install_vagrant.sh
bash install_vagrant.sh
```

#### Create a vagrant project and provision it using ansible.
- `create_vagrant_project.sh` file sets up the Vagrant project:
  - Check if vagrant is already installed, else exit
    ```
    if ! command -v vagrant &>/dev/null; then
      echo "Vagrant is not installed. Please run the install_vagrant.sh script to install Vagrant first."
      exit 1
    fi
    ```
  - Check if virtualbox is already installed, else exit
    ```
    if ! command -v VBoxManage &>/dev/null; then
      echo "VirtualBox is not installed. Please install VirtualBox before setting up the VM."
      exit 1
    fi
    ```
  - Change directory for your Vagrant project where `Vagrantfile` is defined
    ```
    cd ..
    ```
  - Start the VM with Vagrant
    ```
    vagrant up
    ```
  - Configure the VM (runs the ansible playbook `playbook.yml` as configured in the `Vagrantfile`)
    ```
    vagrant provision
    ```
- `Vagrantfile` starts a VM box and runs ansible playbook `playbook.yml` to configure the VM
  - Start VM box with ubuntu 18 image
    ```
    config.vm.box = "ubuntu/bionic64"
    ```
  - Enable Ansible provisioning, uses local ansible setup (`ansible_local`) and runs `playbook.yml` file.
    ```
    config.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "playbook.yml"
    end
    ```
- `playbook.yml` used for configuring the VM
  - Setup hostname of VM as `demo-ops`.
    ```
    - name: Set the hostname to demo-ops
      hostname:
        name: demo-ops
      become: true
    ```
  - Create a user `demo`, also added it to sudoers group.
    ```
    - name: Creating user demo with sudo access
      user:
        name: demo
        password: "{{ 'super_secret_password' | password_hash('sha512', 'superstrongsalt') }}"
        groups: sudo
    ```
    We use `password_hash` to provide hashed password to ansible and use salt to maintain the consistency of the hash.

  - Disable root login
    ```
    - name: Disable Root Login
      lineinfile:
            dest: /etc/ssh/sshd_config
            regexp: '^PermitRootLogin'
            line: "PermitRootLogin no"
            state: present
            backup: yes
      notify: Restart SSH
    ```
    We are using `ansible.builtin.lineinfile` module, this checks the `/etc/ssh/sshd_config` file for a line that starts with `PermitRootLogin` and replaces it with `PermitRootLogin no`, if the regexp is not present, it appends the line at the end of the file. This also sends a notification to `Restart SSH` handler which restarts the sshd service.

  - Setup a basic firewall (e.g., UFW) allowing only specific ports.
    ```
     - name: Install ufw
      apt: package=ufw state=present

    - name: Configure ufw defaults
      ufw: direction={{ item.direction }} policy={{ item.policy }}
      with_items:
        - { direction: 'incoming', policy: 'deny' }
        - { direction: 'outgoing', policy: 'allow' }
      notify:
        - restart ufw

    - name: Configure ufw rules
      ufw: rule={{ item.rule }} port={{ item.port }} proto={{ item.proto }}
      with_items:
        - { rule: 'allow', port: '22', proto: 'tcp' }
        - { rule: 'allow', port: '80', proto: 'tcp' }
        - { rule: 'allow', port: '443', proto: 'tcp' }
      notify:
        - restart ufw

    - name: Enable ufw
      ufw: state=enabled
    ```
    - Install ufw.
    - Set default as `deny` for all `incoming` and `allow` for all `outgoing`.
    - Allow incoming on port `22`, `80`, and `443`.
  - Configure `sysctl` for sane defaults. (For eg: increasing open files limit)
    ```
    - name: Set sysctl parameters
      sysctl:
        name: "{{ item.name }}"
        value: "{{ item.value }}"
        sysctl_set: yes
        state: present
        reload: yes
      loop:
        - { name: "fs.file-max", value: 65535 }
        - { name: "net.ipv4.tcp_syncookies", value: 1 }
        - { name: "vm.swappiness", value: 10 }
    ```
    - `fs.file-max`: sets the maximum number of file-handles that the Linux kernel will allocate. This value is tuned to improve the number of open files, (256 for 4 MB of RAM). We are setting to 65535 for ~2GB of RAM.
    - `net.ipv4.tcp_syncookies`: when enabled it sends out syncookies when the syn backlog queue of a socket overflows. This is to prevent against the common ‘SYN flood attack’.
    - `vm.swappiness`: It controls the relative weight given to swapping out of runtime memory, as opposed to dropping memory pages from the system page cache. The lower the value, the less swapping is used and the more memory pages are kept in physical memory. We are reducing it to 10 to allow redis to use more physical memory.
  - Set the system's timezone to "Asia/Kolkata"
    ```
    - name: Set system timezone
      timezone:
        name: Asia/Kolkata
    ```
  - Install Docker and Docker-Compose.
    ```
    - name: Install aptitude
      apt:
        name: aptitude
        state: latest
        update_cache: true

    - name: Install required system packages
      apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
          - python3-pip
          - virtualenv
          - python3-setuptools
        state: latest
        update_cache: true

    - name: Add Docker GPG apt Key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker Repository
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu jammy stable
        state: present

    - name: Update apt and install docker-ce
      apt:
        name: docker-ce
        state: latest
        update_cache: true

    - name: Install Docker Module for Python
      pip:
        name:
        - docker
        - docker-compose

    - name: Add demo user to docker group
      user:
        name: "demo"
        groups: "docker"
        append: yes

    - name: Install docker-compose
      remote_user: ubuntu
      get_url:
        url: https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64
        dest: /usr/local/bin/docker-compose
        mode: 'u+x,g+x'
    ```
  - Configure Docker Daemon to have sane defaults. For eg: keep logs size in check.
    ```
    - name: Configure Docker Daemon
      copy:
        src: docker-daemon.json
        dest: /etc/docker/daemon.json
      notify: Restart Docker
    ```
    - Sets the `log-driver` as `json-file`.
    - sets `max-size` (max size of log files) of logs to `20m`.
    - sets `max-file` (max number of log files) to 5.
  - Deploy the `docker-compose.yml` in `/etc/demo-ops` and start the services.
    ```
    - name: Create a directory if it does not exist
      ansible.builtin.file:
        path: /etc/demo-ops
        state: directory
        mode: '0755'

    - name: copy Docker Compose files
      copy:
        src: "{{ playbook_dir }}/../docker/docker-compose.yaml"
        dest: /etc/demo-ops/docker-compose.yaml
      become: true

    - name: deploy Docker Compose stack
      community.docker.docker_compose:
        project_src: /etc/demo-ops
    ```
    - Creates a directory `/etc/demo-ops`.
    - Copy the docker compose files, uses a special ansible var `playbook_dir` which is the directory where the playbook is present.
    - Starts the `docker-compose.yaml` present in `/etc/demo-ops` directory.
  - At the end of the main playbook, it imports 4 other playbooks:
    ```
    - name: Include Node Exporter Installer Playbook
      ansible.builtin.import_playbook: node-exporter-installer.yaml

    - name: Include Redis Exporter Installer Playbook
      ansible.builtin.import_playbook: redis-exporter-installer.yaml

    - name: Include Prometheus Installer Playbook
      ansible.builtin.import_playbook: prometheus-installer.yaml

    - name: Include Grafana Installer Playbook
      ansible.builtin.import_playbook: grafana-installer.yaml
    ```
    - `node-exporter-installer.yaml`: To install Node Exporter.
      - Creates a user and group called `node_exporter`
      - Downloads and extracts Node Exporter v1.6.1 (latest at the time of writing)
      - Copies the extracted folder to bin
      - Generates `node_exporter.service` from template. This creates a service called `node_exporter`, which is run by user `node_exporter`
      - Starts the node exporter service
      - Wait till the service is up on `http://127.0.0.1:9100/metrics`
    - `redis-exporter-installer.yaml`: To install Redis Exporter.
      - Creates a user and group called `redis_exporter`
      - Downloads and extracts Redis Exporter v1.54.0 (latest at the time of writing)
      - Copies the extracted folder to bin
      - Generates `redis_exporter.service` from template. This creates a service called `redis_exporter`, which is run by user `redis_exporter`
      - Starts the redis exporter service
      - Wait till the service is up on `http://127.0.0.1:9121/metrics`
    - `prometheus-installer.yaml`: To install Prometheus.
      - Creates a user and group called `prometheus`
      - Downloads and extracts Prometheus v2.47.0 (latest at the time of writing)
      - Copies the extracted folder to bin
      - Creates directories `/data/prometheus/` and `/etc/prometheus/` for storing logs and service configs respectively.
      - Generates a `prometheus.conf` file from template which scrapes
        - prometheus: `localhost:9090`
        - node_exporter: `localhost:9100`
        - redis_exporter: `localhost:9121`
      - Generates `prometheus.service` from template. This creates a service called `prometheus`, which is run by user `prometheus`
      - Starts the prometheus service
      - Wait till the service is up on `http://localhost:9090`
    - `grafana-installer.yaml`: To install Grafana.
      - Installs gpg using `apt` ansible module.
      - Adds grafana gpg key using `apt_key` ansible module.
      - Adds grafana apt repository using `apt_repository` ansible module.
      - Installs grafana using `apt`.
      - Starts grafana service called `grafana-server` using `systemd`.
      - Waits till the service is up on `http://127.0.0.1:3000`.

Run The script using bash
```
chmod +x create_vagrant_project.sh
bash create_vagrant_project.sh
```

<br>

***

***

### Kubernetes

The solution to this task is defined in the `kubernetes` folder of this repository
```
cd kubernetes
```

- Create a namespace `demo-ops`.
  ```
  kubectl apply -f namespace.yaml
  ```
  Creates a namespace in kubernetes called `demo-ops`. All subsequent resources will be created in this namespace by adding `namespace: demo-ops` in metadata section.

- Create Resource Quota.
  ```
  kubectl apply -f resource-quota.yaml
  ```
  Sets hard quotas on:
  - pods: `10`
  - requests.cpu: `1` (1k)
  - requests.memory: `1Gi` (1GB)
  - limits.cpu: `2` (2k)
  - limits.memory: `2Gi` (2GB)
  Verify the quota by running, run this after creating all resources to view the Used quota
  ```
  kubectl describe quota -n demo-ops
  ```

- Create Redis PVC.
  ```
  kubectl apply -f redis-pvc.yaml
  ```
  - storage of `1Gi`
  - access mode as `ReadWriteOnce`, can be mounted with read write access by a single node.

- Create Redis deployment and service
  ```
  kubectl apply -f redis.yaml
  ```
  - Creates a deployment named `redis-deployment`
    - runs 1 replica
    - uses latest Official Redis image
    - Exposes port `6379` on container and host
    - Resource
      - limit: `0.5` CPU and `512Mi` of memory.
      - request: `0.2` CPU and `256Mi` of memory.
    - Mounts a volume `redis-data` on `/data` of container which uses pvc `redis-pvc` created earlier.
  - Creates a service named `redis-service` which defines port `6379` of pod and host.

- Create App deployment and service
  ```
  kubectl apply -f app.yaml
  ```
  - Creates a deployment named `app-deployment`
    - runs 1 replica
    - uses local image of `zerodha-demo-app:latest`
    - Exposes port `8080` on container and host
    - Uses two Environment Variables
      - `DEMO_APP_ADDR`: `:8080`
      - `DEMO_REDIS_ADDR`: `redis-service:6379` (`redis-service` Service created above)
    - LivenessProbe
      - hits `/` path on port `8080` every `10s` with first time delay of `10s`
    - Resource
      - limit: `0.5` CPU and `512Mi` of memory.
      - request: `0.2` CPU and `256Mi` of memory.
  - Creates a service named `app-service` which defines port `8080` of pod and host.

- Create Nginx PV
  ```
  cat nginx-pv.yaml | sed s+{{path}}+$(pwd)+g | kubectl apply -f -
  ```
  - Note: this command is always to be run from the folder where the `nginx-pv.yaml` exists.
  - The above command replaces the `path` variable with output of `pwd` before running `kubectl apply`.
  - Creates a volume with `1Gi` of storage and `ReadWriteOnce` access mode.
  - Mounts `nginx-conf` directory to this volume. This folder contains `default.conf` that contains nginx configuration.

- Create Nginx PVC
  ```
  kubectl apply -f nginx-pvc.yaml
  ```
  - storage of `1Gi`
  - access mode as `ReadWriteOnce`, can be mounted with read write access by a single node.
  - As soon as the PVC is created, it gets binded to `nginx-pv` resource.

- Create Nginx deployemnt and service
  ```
  kubectl apply -f nginx.yaml
  ```
  - Creates a deployment named `nginx-deployment`
    - runs 1 replica
    - uses latest Official Nginx image
    - Exposes port `80` and `443` on container and host
    - Resource
      - limit: `0.5` CPU and `512Mi` of memory.
      - request: `0.2` CPU and `256Mi` of memory.
    - Mounts a volume `nginx-conf` on `/etc/nginx/conf.d` of container which uses pvc `nginx-pvc` created earlier.
  - Creates a service named `nginx-service` which defines port `80` and `443` of pod and host.

- Create port forwarding
  ```
  kubectl port-forward service/nginx-service 80:80 -n demo-ops
  ```
  - This forwards local port `80` to port `80` on the `nginx-service`
  - Port Forwarding is used here to access the Go Applications of the k8 cluster in our local browser.

- Check Application on Browser
  - Open your browser and enter the url `http://localhost`, you should get an output like
    ```
    welcome to api. key count is: 4
    ```


<br>

***

***

### Nomad

The solution to this task is defined in the `nomad` folder of this repository
```
cd nomad
```

#### Start a dev agent

```
nomad agent -dev -bind 0.0.0.0 -network-interface='{{ GetDefaultInterfaces | attr "name" }}'
```

#### Create a namespace

Nomad has support for namespaces, which allow jobs and their associated objects to be segmented from each other and other users of the cluster.
```
nomad namespace apply -description "Namespace for deploying demo app" demo-ops
```

#### Nomad Job spec

The `demo-app.nomad.hcl` Job spec does the following:
- Creates a job called `zerodha-demo-app`.
- Sets the datacentre as `dc1`.
- Sets the namespace as `demo-ops`.
- Sets he type of job as `service`.
- Creates a group called `cache` for redis.
  - `network` block defines a port `db` (`6379`) and `to` to configure port to map to tasks's network. (mode=`bridge` does not wokr on mac)
  - `service` block registers a service to named `app-redis` which uses port `db` and specifies the provider as `nomad`.
  - `task` block creates an individual unit of work called `redis`
    - Uses `docker` driver
    - Config block defines the image (`redis:latest`) and ports (`db`) used.
  - `resources` block specifies the min resource requirement (256 cpu and memory)
- Creates a group called `demo-app` for our Go app.
  - `network` block defines a port `http` (`8080`) and `to` to configure port to map to tasks's network.
  - `service` block registers a service to named `app-http` which uses port `http` and specifies the provider as `nomad`.
  - `task` block creates an individual unit of work called `app`
    - Uses `docker` driver
    - Config block defines the image (`zerodha-demo-app:local`) (Note: using `local` tag to pull the image from local, if not already created, tag the already existing `zerodha-demo-app:latest` by running the command `docker tag zerodha-demo-app:latest zerodha-demo-app:local`) and ports (`db`) used.
  - `template` block takes the `data` and renders it to the destination `secrets/db.env`. The `env` specifies that the template is to be read as an env var for the task. The `change_mode` specifies that the task will be restarted if the data is changed.
  - `resources` block specifies the min resource requirement (500 cpu and 256 memory)
- Creates a group called `nginx` for Nginx.
  - `network` block defines a port `http` (`80` and `443`) and `to` to configure port to map to tasks's network.
  - `service` blocks registers two services to named `nginx-http` and `nginx-https` which uses port `http` and `https` respectively, and specifies the provider as `nomad`.
  - `task` block creates an individual unit of work called `nginx`
    - Uses `docker` driver
    - Config block defines the image (`nginx:latest`) and ports (`http` and `https`) used.
    - Mount block binds the source file to a destination on the container. Here we are mounting `default.conf`, `zerodha-demo-app.crt` and `zerodha-demo-app.key`.
  - `template` block takes the `data` (in this case, a file on host) and renders it to the destination on nomad local. The `change_mode` specifies that the task will be restarted if the data is changed.
  - `resources` block specifies the min resource requirement (500 cpu and 256 memory)

Run the Job Spec:
```
nomad job run demo-app.nomad.hcl
```


<br>

***

***

### Makefile

List of commands available:
- `docker-build`: builds the docker image zerodha-demo-app:latest
  ```
  make docker-build
  ```

- `docker-tag-local`: creates a new tag `zerodha-demo-app:local` of the above image
  ```
  make docker-tag-local
  ```

- `docker-compose-up`: starts the `docker-compose.yaml` file in detached mode
  ```
  make docker-compose-up
  ```

- `docker-compose-down`: stops the `docker-compose.yaml` file
  ```
  make docker-compose-down
  ```

- `install-vagrant`: executes the `install_vagrant.sh` script.
  ```
  make install-vagrant
  ```

- `create-vagrant-project`: executes the `create_vagrant_project.sh` file
  ```
  make create-vagrant-project
  ```

- `deploy-kubernetes`: deploys all the kubernetes resources
  ```
  make deploy-kubernetes
  ```

- `delete-kubernetes`: deletes all the kubernetes resources
  ```
  make delete-kubernetes
  ```

- `deploy-nomad`: creates a namespace and runs the `demo-app.nomad.hcl` job. Nore: does not start the dev agent.
  ```
  make deploy-nomad
  ```