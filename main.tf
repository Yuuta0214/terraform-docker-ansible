terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# --- ネットワークの作成 ---
# Public NetWork
resource "docker_network" "public_nw" {
  name = "public_network"
}

# private NetWork
resource "docker_network" "private_nw" {
  name = "private_network"
  internal = true # 外部へのルートを持たない設定
}

# --- コンテナの作成 ---
# public側に配置するコンテナ（Webなど）
resource "docker_container" "public_server" {
  name = "public_node"
  image = "ubuntu:22.04"
  entrypoint = [
  "/bin/bash", "-c", 
  "apt update && apt install -y openssh-server && echo 'root:root' | chpasswd && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && service ssh start && tail -f /dev/null"
]
  
  # １つ目のNW：Public
  networks_advanced {
    name = docker_network.public_nw.name
  }
  
  # ２つ目のNW：Private
  networks_advanced {
    name = docker_network.private_nw.name
  }
  ports {
    internal = 80
    external = 8081
  }

  # SSH用の2222
  ports {
    internal = 22
    external = 2222
  }
 } 

# Private側に配置するコンテナ（DBなど）
resource "docker_container" "private_server" {
  name = "private_node"
  image = "ubuntu:22.04"
  entrypoint = [
  "/bin/bash", "-c", 
  "apt update && apt install -y openssh-server && echo 'root:root' | chpasswd && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && service ssh start && tail -f /dev/null"
]

  # 一時的にこれらを追加
  networks_advanced {
    name = docker_network.public_nw.name
  }

  networks_advanced {
    name = docker_network.private_nw.name
  }
}
