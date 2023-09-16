job "zerodha-demo-app" {
  datacenters = ["dc1"]
  namespace   = "demo-ops"
  type        = "service"

  group "cache" {
    network {
      port "db" {
        to = 6379
      }
    }

    service {
      provider = "nomad"
      name     = "app-redis"
      port     = "db"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:latest"
        ports = ["db"]
      }

      resources {
        cpu    = 256
        memory = 256
      }
    }
  }

  group "demo-app" {
    network {
      port "http" {
        to = 8080
      }
    }

    service {
      provider = "nomad"
      name     = "app-http"
      port     = "http"
    }

    task "app" {
      driver = "docker"

      config {
        image = "zerodha-demo-app:local"
        ports = ["http"]
      }

      template {
        data = <<EOF
	{{ with nomadService "app-redis" }}
	{{ range nomadService "app-redis" }}
        DEMO_APP_ADDR = ":8080"
        DEMO_REDIS_ADDR = "{{ .Address }}:{{ .Port }}"
	{{ end }}
	{{ end }}
EOF
          destination = "secrets/db.env"
          env         = true
          change_mode = "restart"

        }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }

  group "nginx" {
    network {
      port "http" {
        to = 80
        static = 80
      }
      port "https" {
        to = 443
        static = 443
      }
    }

    service {
      provider = "nomad"
      name     = "nginx-http"
      port     = "http"
    }

    service {
      provider = "nomad"
      name     = "nginx-https"
      port     = "https"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        ports = ["http", "https"]

        mount {
          type = "bind"
          source = "local/nginx-default.conf"
          target = "/etc/nginx/conf.d/default.conf"
        }

        mount {
          type = "bind"
          source = "local/zerodha-demo-app.crt"
          target = "/etc/nginx/ssl/zerodha-demo-app.crt"
        }

        mount {
          type = "bind"
          source = "local/zerodha-demo-app.key"
          target = "/etc/nginx/ssl/zerodha-demo-app.key"
        }
      }

      template {
        data = file(abspath("./nginx/nginx-conf/default.conf"))
        destination = "local/nginx-default.conf"
        change_mode = "restart"
      }

      template {
        data = file(abspath("./nginx/ssl/zerodha-demo-app.crt"))
        destination = "local/zerodha-demo-app.crt"
        change_mode = "restart"
      }

      template {
        data = file(abspath("./nginx/ssl/zerodha-demo-app.key"))
        destination = "local/zerodha-demo-app.key"
        change_mode = "restart"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}