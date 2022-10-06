terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

variable "services" {
  type    = list(string)
  default = ["mysql"]
}

variable "dotfiles" {
  type    = list(string)
  default = [".my-profile", ".my-alias", ".my-env", ".my-functions"]
}

variable "scripts" {
  type    = list(string)
  default = ["changefont"]
}

resource "null_resource" "brew-casks-install" {
  provisioner "local-exec" {
    command = "brew install --cask $(cat cask.txt | tr \"\\n\" \" \")"
  }
}

resource "null_resource" "brew-formulae-install" {
  provisioner "local-exec" {
    command = "brew install $(cat formulae.txt | tr \"\\n\" \" \")"
  }
}

resource "null_resource" "brew-services-install" {
  for_each = toset(var.services)
  provisioner "local-exec" {
    command = "brew services start ${each.key}"
  }
  depends_on = [
    null_resource.brew-formulae-install
  ]
}

resource "null_resource" "scripts-install" {
  for_each = toset(var.scripts)
  provisioner "local-exec" {
    command = "sudo cp bin/${each.key} /usr/local/bin"
  }
}

resource "null_resource" "terminal-updates" {
  provisioner "local-exec" {
    command = "rm -rf $${HOME}/.oh-my-zsh"
  }

  provisioner "local-exec" {
    command = "sh -c \"$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" 2>/dev/null"
  }

  provisioner "local-exec" {
    command = "echo \"source ~/.my-profile\" >> $${HOME}/.zshrc"
  }
}

resource "null_resource" "java-updates" {
  provisioner "local-exec" {
    command = "sudo ln -sfn /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk"
  }
  depends_on = [
    null_resource.brew-formulae-install
  ]
}

resource "null_resource" "docker-updates" {
  provisioner "local-exec" {
    command = "mkdir -p $${HOME}/.docker/cli-plugins && ln -sfn /usr/local/opt/docker-compose/bin/docker-compose $${HOME}/.docker/cli-plugins/docker-compose"
  }
  depends_on = [
    null_resource.brew-formulae-install
  ]
}

