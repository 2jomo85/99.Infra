# Docker 를 이용한 React + Django + Nginx + Maria DB 환경 구축

## 1. Docker 설치

[Docker Doc](https://docs.docker.com/engine/install/ubuntu/)

### Old Version 삭제

```shell
sudo apt-get remove docker docker-engine docker.io containerd runc
```

### Set up the repository

1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:

```shell
sudo apt-get update
sudo apt-get install \
   ca-certificates \
   curl \
   gnupg \
   lsb-release
```

2. Add Docker’s official GPG key:

```shell
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

3. Use the following command to set up the repository:

```shell
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker Engine

1. Update the apt package index, and install the latest version of Docker Engine, containerd, and Docker Compose, or go to the next step to install a specific version:

```shell
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

2. To install a specific version of Docker Engine, list the available versions in the repo, then select and install:
   a. List the versions available in your repo

   ```shell
   apt-cache madison docker-ce
   ```

   b. Install a specific version using the version string from the second column, for example, 5:20.10.16~3-0~ubuntu-jammy.

   ```shell
   sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io docker-compose-plugin
   ```

3. Verify that Docker Engine is installed correctly by running the hello-world image.

```shell
sudo service docker start
sudo docker run hello-world
```

> ### sudo 없이 docker 사용
>
> ```shell
> # 현재 계정을 docker group 에 포함 시킨다.
> sudo usermod -aG docker ${USER}
>
> ##### 아래 2줄은 현재 계정으로 다시 로그인하기 위한 일종의 trick 이다.
> ##### 만약 아래처럼 못하면 그냥 exit으로 아예 터미널 종료 후, 다시 로그인을 시도한다.
> sudo su - # 루트 계정으로 접속
> su - ubuntu # 다시 원래 계정으로 로그인
>
> # 제대로 docker 라는 group에 들어갔는지 확인한다.
> # "docker"라는 문구가 보이면 성공한 것이다.
> groups ubuntu
>
> # sudo 없이 되는지 테스트해보자. 아래 명령어는 docker 명령어 테스트용으로 자주 쓴다.
> docker run hello-world
> ```

## 2. Docker-compose 설치

```shell
sudo curl -L \
"https://github.com/docker/compose/releases/download/1.28.5/dockercompose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
# 이 명령어는 외부에서 그대로 파일을 가져와서 현재의 시스템에 올려 놓는 것이다.
## 결과적으로 "/usr/local/bin/" 경로에 "docker-compose" 라는 이름의 파일로 다운된다.
## 참고) https://github.com/docker/compose/releases 에서 최신 버전 확인이 가능하다.
## 최신 버전을 설치하고 싶다면 위 명령어에 보이는 1.28.5 라는 버전 숫자를 바꿔주면 된다!
## chmod 를 통해서 실행이 가능하게 세팅
sudo chmod +x /usr/local/bin/docker-compose
## docker-compose 명령이 제대로 먹히는 지 확인한다.
docker-compose -v
```

## 3. 작업폴더 하위에 기본 폴더 및 파일 생성

```console
mkdir backend
mkdir fromtend
mkdir mariadb
mkdir mariadb/volume
mkdir mariadb/sql
touch docker-compose.yml
```

## 4. Backend 와 DB 설정

web 과 nginx 폴더를 생성한다.

```shell
cd backend \
 && mkdir web \
 && mkdir nginx
```

#### web-Django 준비

```shell
cd web \
 && touch .env Dockerfile requirements.txt
```

backend/web/.env

```
SECRET_KEY='1234567890'
DEBUG=False
```

backend/web/Dockerfile

```Dockerfile
# backend/web/Dockerfile
# set base image
FROM python:3.10.2

# set environment variables
ENV PYTHONDOWNTWRITTEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# set work directory
WORKDIR /code

# install dependencies
COPY requirements.txt ./
RUN python3 -m pip install --upgrade pip setuptools
RUN pip install -r requirements.txt

# Copy project
COPY . ./

# Expose application port
EXPOSE 8000
```

backend/web/requirements.txt

```
asgiref==3.5.0
Django==4.0.2
django-cors-headers==3.11.0
djangorestframework==3.13.1
gunicorn==20.1.0
mysqlclient==2.1.0
python-dotenv==0.19.2
pytz==2021.3
sqlparse==0.4.2
```

#### Nginx 준비

Dockerfile 과 conf 파일을 dev 로 만드는 이유는, 향후 배포를 위해 파일을 분리하기 위함이다.

```shell
cd ../nginx \
 && touch Dockerfile.dev default.dev.conf
```

backend/nginx/Dockerfile.dev

```Dockerfile
FROM nginx:1.21.6-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY default.dev.conf /etc/nginx/conf.d
```

backend/nginx/default.dev.conf

```conf
upstream django {
  server web:8000;
}

server {

  listen 80;

  location = /healthz {
    return 200;
  }

  location / {
    proxy_pass http://django;
    proxy_set_header Host $host;
    proxy_set_header X-Fowarded-For $proxy_add_x_forwarded_for;
    proxy_redirect off;
  }

  location /static/ {
    alias /code/staticfiles/;
  }
}
```

#### MariaDB 준비

```shell
cd ../../mariadb \
 && touch .env Dockerfile my.cnf \
 && cd sql \
 && touch init.sql
```

mariadb/.env

```
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=password
MYSQL_DATABASE=testdb
MYSQL_USER=user
MYSQL_PASSWORD=password
```

mariadb/Dockerfile

```dockerfile
FROM mariadb:10.7.1

RUN ehck "USE mysql;" > docker-entrypoint-initdb.d/timezones.sql && mysql_tzinfo_to_sql /usr/share/zoneinfo >> docker-entrypoint-initdb.d/timezones.sql

COPY ./my.cnf /etc/mysql/conf.d/my.cnf
```

mariadb/my.cnf

```conf
# Settings for MySQL server
[mysqld]
character-set-client-handshake=FALSE

## Character code/Collation settings
character_set_server=utf8mb4
collation_server=utf8mb4_bin

## Setting the default authentication plugin
default_authentication_plugin=mysql_native_password

# Setting mysql options
[mysql]
## Character code setting
default_character_set=utf8mb4

# mysql client tool settings
[client]
## Character code setting
default_character_set=utf8mb4
```

mariadb/sql/init.sql

```sql
CREATE DATABASE testdb;
CREATE user 'user' identified BY 'password';
GRANT ALL PRIVILEGES ON testdb.* TO 'user'@'%';
```

## 5. docker-compose 로 Backend 시작

### docker-compose.yml 작성

```docker
version: "3.7"

services:
  web:
    container_name: web
    env_file: ./bacnekd/web/.env
    build: ./backend/web/.
    volumes:
      - ./backend/web:/code/
      - static_volume:/code/staticfiles # <-- bind the static volume
    stdin_open: true
    tty: true
    command: gunicorn --bind :8000 config.wsgi:application
    networks:
      - backend_network
    environment:
      - CHOKIDAR_USEPOLLING=true
      - DJANGO_SETTINGS_MODULE=config.local_settings
    depends_on:
      - db
  bacnekd-server:
    container_name: nginx-back
    build:
      context: ./backend/nginx/.
      dockerfile: Dockerfile.dev
    volumes:
      - static_volume:/code/staticfiles # <-- bind the static volume
    ports:
      - "8080:80"
    depends_on:
      - web
    networks:
      - backend_network
  db:
    container_name: db
    build: ./mariadb
    command: mysqld --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    env_file: ./mariadb/.env
    environment:
      TZ: "Asia/Seoul"
    volumes:
      - ./mariadb/volume:/var/lib/mysql
      - ./mariadb/sql:docker-entrypoint-initdb.db
    networks:
      - backend_network
    # restart: always # <-- always runnung...
networks:
  backend_network:
    driver: bridge
volumes:
  static_volume:

```

docker-compose 실행

```shell
# manage.py 생성
docker-compose run --rm web sh -c "django-admin startproject config ."
#
docker-compose run --rm web sh -c "python manage.py startapp todo"
```

## 개발환경과 설정파일

개발환경과 프로덕션 환경에 대한 설정 파일을 분리하고 싶기 때문에, <span style='background-color: #f6f8fa'>web/config</span> 폴더 하위에<span style='background-color: #f6f8fa'>local_settings.py</span> 파일을 생성.

web/config/local_settings.py

```py
from .settings import *

DEBUG = True

ALLOWED_HOSTS = ['*']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'testdb',
        'USER': 'user',
        'PASSWORD': 'password',
        'HOST': 'db',
        'PORT': '3306',
    }
}
```

```shell
# build
docker-compose up --build
```
