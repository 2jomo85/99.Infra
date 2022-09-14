# Vargrant + Ansible + Docker 로컬 개발환경 구성하기

## 개발환경 구성

> vagrant 를 실행하여 가상 머신 환경을 구성하고, ansible 를 통하여 개발환경에 필요한 패키지를 설치하며, Docker 를 통하여 최종적으로 개발환경을 구성 완료하려고 함.

### Virtual box 설치

아래 링크에서 VirtualBox 를 설치.  
[VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Vagrant 설치

아래 링크에서 Vagrant 설치.  
[Vagrant](https://www.vagrantup.com/downloads)

### Vagrant 실행

```console
# vagrant 도움말
vagrant --help

# Vagrantfile 생성
vagrant init
```

### Vagrantfile

```console
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder ".", "/vagrant"
  config.vm.define :ubuntu do |host|
    host.vm.box = "bento/ubuntu-18.04"
    host.vm.hostname = "ubuntu"
    host.vm.network :private_network, ip: "192.168.2.10"

    host.vm.disk :disk, size: "10GB", primary: true
    host.vm.provision :shell, path: "bootstrap.sh"

    # Set system settings
    host.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "2048"]
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000 ]
    end
  end
end
```

1. config.vm.synced_folder는 호스트 PC의 폴더와 가상 머신 환경에서 /vagrant 폴더로 마운트 됩니다.
2. host.vm.box 는 가상머신 환경에 사용할 기본 이미지 이며, ubuntu 18.04 이미지 사용합니다. https://app.vagrantup.com/boxes/search 사이트에 가시면 다양한 이미지가 공개되어 있고, 필요한 이미지를 검색해서 사용하시면 됩니다.
3. host.vm.network 는 가상머신에서 사용할 private ip 주소를 설정합니다.
4. host.vm.disk는 가상 머신이 사용할 Disk 크기를 설정합니다.
5. host.vm.provision는 가상머신이 실행되고 초기 provision를 하기 위한 shell 파일을 설정합니다.
6. host.vm.provider 는 가상머신의 CPU, Memory 사용량을 할당하며, 호스트 PC와 가상머신 환경의 시간 동기화를 위한 설정합니다.

```console

#!/bin/bash

set -e

rm -rf /var/lib/apt/lists/*
sed -i 's/archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list
apt-get update -y
```

bootstrap.sh 파일은 가상머신 실행 후 해당 스크립트를 실행해서 가상머신의 환경을 설정합니다. 위의 내용은 패키지 다운로드 주소를 ftp.daum.net 주소로 설정을 합니다. 그 외 다양하게 개발 환경에 필요한 Redis, Memcached, Nginx, Apache 서버와 같은 패키지를 설치할 수 있습니다.
