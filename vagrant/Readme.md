# Vargrant + Ansible + Docker 로컬 개발환경 구성하기

## 개발환경 구성

> vagrant 를 실행하여 가상 머신 환경을 구성하고, ansible 를 통하여 개발환경에 필요한 패키지를 설치하며, Docker 를 통하여 최종적으로 개발환경을 구성 완료하려고 함.

### Virtual box 설치

아래 링크에서 VirtualBox 를 설치.  
[VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Vagrant 설치

아래 링크에서 Vagrant 설치.  
[Vagrant](https://www.vagrantup.com/downloads)

### Vagrant 명령어

```console
# vagrant box 추가 (어느 경로에서 실행을 해도 상관없음)
$ vagrant box add ubuntu/focal64

# 홈디렉토리의 .vagrant.d/boxes 디렉토리에 해당 box 명으로 이미지가 만들어진다.
$ ls ~/.vagrant.d/boxes/

# box 목록 확인
$ vagrant box list
ubuntu/focal64 (virtualbox, 20210413.0.0)

# vagrant 프로젝트 디렉토리 생성. 파일 관리를 편리하게 하기 위한 것임.
필수는 아니나 디렉토리를 잘 관리하는게 편리함.
vagrant init 를 하면 해당 디렉토리에 Vagrantfile 이 만들어지므로 이것을 참고하여 디렉토리 구조 만듬.
$ mkdir porject/test
$ cd project/test

# vagrant instance 생성 (이 과정에서 설정파일인 Vagrantfile 이 만들어짐)
$ vagrant init ubuntu/focal64

# vagrant instance 시작하기(부팅)
$ vagrant up

# ssh 접속하기. vagrant ssh 로 접속시에는 비밀번호 없이 자동접속 가능함.
# 또는 host 127.0.0.1 ,port 2222, username vagrant 로 설정을 하여 putty 등에서도 접속을 할 수도 있음.
$ vagrant ssh

# vagrant VM shutdown
$ vagrant halt

# vagrant box 없애기
$ vagrant destroy

# 새로운 vagrant box 생성하기
$ vagrant up
```

### vagrant 설정폴더 변경

Vagrant global state 정보를 저장하는 VAGRANT_HOME 변수를 변경할 수 있으며 기본값은 ~/.vagrant.d 이다. boxes 등을 이 디렉토리에 저장 하기 때문에 디스크 용량을 많이 차지할 가능성이 많다.

이 부분을 윈도우에서 변경을 하려면 c:\users\yourusename 의 .bashprofile 에 다음의 내용을 넣어주면 된다.

```bach
setx VAGRANT_HOME "D:\.vagrand.d"
```

## vagrant 설정 변경하기

vagrant init 를 하면 명렁을 실행한 해당 디렉토리에 Vagrantfile 파일이 생긴다. 이 파일을 수정하면 vagrant up 을 할 때 여러가지 작업을 조합할 수 있다.

### vagrant 주요 옵션

`vm.box`: 사용할 이미지
`vm.network : fowarded_port`: 호스트의 port 를 VM guest 의 지정 포트로 포워드
`vm.network "private_network"`: VM 에 ip 지정
`vm.provision`: 특정 명령어 실행, 스크립트 실행 등
`vm.hostname`: hostname설정

```ini
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.network :forwarded_port, guest: 80, host: 4567
  config.vm.network "private_network", ip: "192.168.33.100"

#  config.vm.provision "shell", path: "test.sh"

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
    echo "test" > /var/www/html/index.html
  SHELL

  config.vm.hostname = 'www.example.com'
end
```

### vagrant provisioning -shell

처음으로 vagrant up 을 할 때 프로비저닝이 실행된다. 첫 가동 이후에는 vagrant up --provision 을 지정해서 가동하거나 가상 서버 가동 후에 vagrant provision 을 실행하면 프로비저닝이 가능하다.

sehll 을 이용하여 프로비저닝 하는 것이 가능하며 inline 을 이용 원하는 스크립트를 실행할 수 있다.

[Shell Scripts - Provisioning | Vagrant | HashiCorp Developer]("https://docs.vagrantup.com/v2/provisioning/shell.html")

```bash
vim Vagrantfile
  Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"
    config.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y apache2
    SHELL
  end

vagrant provision
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

### Vagrant 실행

```console
# vagrant 실행
vagrant up
# ssh 접속
vagrant ssh

# docker compose 로 nginx 실행
cd /vagrant/docker/nginx
docker-compose up -d
```

192.168.2.10 접속하면 nginx 접속화면을 확인 가능.
