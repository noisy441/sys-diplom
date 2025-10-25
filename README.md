# Дипломная работа по профессии «Системный администратор» - Дудин Сергей Васильевич

Ключевая задача дипломной работы разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. 

[Полный текст задания для дипломной работы](https://github.com/netology-code/sys-diplom/tree/diplom-zabbix?tab=readme-ov-file "Полный текст задания для дипломной работы")


# Выполнение работы
Разделю проект на подзадачи и начну выполнять их посчледовательно. 

## Этап 0: Подготовка и настройка окружения

Выполнение работы буду проводить с виртуальной машины под управлением Ubuntu 24

### 1. Установка yc CLI
Начнем подготовку рабочего семта с установки yc CLI, для чего выполним:
 ```
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
 ```
Скрипт установит CLI и добавит путь до исполняемого файла в переменную окружения PATH. Сразу же настроим его с помощью команды ```yc init```, пройдем мастер настройки, на этом ya CLI настроен. 

### 2. Установка и настройка Terraform
Приступим к установке Terraform. Скачиваем нужный нам дистрибутив 
```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.9.7/terraform_1.9.7_linux_amd64.zip
```
Распаковываем скаченный архив 
```
unzip terraform_1.9.7_linux_amd64.zip 
```
Копируем распакованный файл и делаем его исполняемым
```
sudo cp terraform /usr/bin/
sudo chmod +x /usr/bin/terraform 
```
В домашнем катаоге создадим файл .terraformrc с указанным содержимым, для того, чтобы иметь возможность устанавливать провайдеры.
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
Создадим в Yandex Cloud сервисный аккаунт с правами editor и скопируем полученный ключ в ```~/.authorized_key.json"```

Создадим в корне проекта файлы providers.tf и variables.tf в котором будем хранить наши переменные. Поверим работу командой 
```
terrafirm init
```
В качестве ответа получим 

>Initializing the backend...
>Initializing provider plugins...
>- Reusing previous version of hashicorp/local from the dependency lock file
>- Reusing previous version of yandex-cloud/yandex from the dependency lock file
>- Using previously-installed yandex-cloud/yandex v0.129.0
>- Using previously-installed hashicorp/local v2.5.3
>
>Terraform has been successfully initialized!

Сразу же создадим в корне файл ````.gitignore``` он понадобится для ограничения публикации в git.

Terraform установлен и готов к работе. 

### 3. Установка Ansible
Для развертывания программного обеспечения нам понадобытся Ansible. Сразу установим его
```
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```


### 4. Выпуск SSH Сертификата
Для работы нам понадобится SSH сертификат, поэтому изготовим его на этапе подготовки. Для изготовлдения сертификата выполним
```
ssh-keygen -t ed25519 -C "мой Email"
```
После выполнения команды, получим приватный и публичный ключи, расположенные по умолчанию в ```~/.ssh/```

Создадим файл cloud-init.yml который понадобится нам для автоматической  настройки виртуальных машин при их создании. Добавим в этот файл наш публичный ключ
```
#cloud-config
users:
  - name: user
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
    - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGVZF4lSDylXP5qjxlriGSdGa4jrCUz9T3iA1dYJiYM noisy44@gmail.com
```

### Этап 1: Проектирование и развертывание сетевой инфраструктуры (Terraform)
*   **Цель:** Создать изолированное сетевое окружение, соответствующее требованиям безопасности. 

1.  **Создание VPC и подсетей:**
    *   Создать один VPC.
    *   Создать 3 подсети:
        *   `public-subnet-a` (Назовем, `ru-central1-a`): для Bastion, Zabbix, Kibana, ALB.
        *   `private-subnet-a` (Назовем, `ru-central1-a`): для Web-сервера 1, Elasticsearch.
        *   `private-subnet-b` (Назовем, `ru-central1-b`): для Web-сервера 2.
    *   Настроить таблицы маршрутизации:
        *   Для `public-subnet-a`: маршрут по умолчанию (`0.0.0.0/0`) на `internet-gateway`.
        *   Для приватных подсетей: маршрут по умолчанию (`0.0.0.0/0`) на `nat-gateway`.

Для реализации этой задачи создадим файл network.tf в котором опишем создание намеченной сетевой инфраструктуры. Разделим конфигурацию на логические блоки. Начнем с создания основной VPC сети с названием "main-network"  далее создадим шлюзы, таблицы маршрутизации и подсети.

2.  **Настройка Security Groups:**
    *   `sg-bastion`: Разрешить входящий SSH (22/tcp) только с моего IP.
    *   `sg-internal`: Разрешить всю коммуникацию внутри самой группы (для общения сервисов между собой).
    *   `sg-web`: Применить к Web-серверам. Разрешить HTTP (80/tcp) только от `sg-balancer` и `sg-zabbix` (для мониторинга).
    *   `sg-balancer`: Применить к ALB. Разрешить HTTP (80/tcp) из интернета.
    *   `sg-zabbix`: Применить к серверу Zabbix. Разрешить входящие порты 80/tcp, 443/tcp (UI) и 10051/tcp (для агентов) из интернета и от `sg-internal`.
    *   `sg-elasticsearch`: Применить к Elasticsearch. Разрешить 9200/tcp только от `sg-kibana` и `sg-internal` (для Filebeat).
    *   `sg-kibana`: Применить к Kibana. Разрешить 5601/tcp из интернета.

Для создания групп безопастности создадим отдельный файл security_groups.tf в котором и опишем конфигурацию. Проверим  работоспособность конфигурации.
Выполним команты
```
terraform plan
terraform apply
```
В yandex cloud успешно создана сетевая инфраструктура. Выполняем 
```
terraform destroy
```
и переходим к следующему этапу - созданию виртуальных машин.

### Этап 2: Создание виртуальных машин и балансировщика (Terraform)
*   **Цель:** Развернуть базовую инфраструктуру веб-сайта.

1.  **Создание ВМ (используем прерываемые, минимальные конфигурации):**
    *   `bastion`: В `public-subnet-a`, с публичным IP. Образ Ubuntu
    *   `web-1`: В `private-subnet-a`, без публичного IP. `name=web-1`, `hostname=web-1`.
    *   `web-2`: В `private-subnet-b`, без публичного IP. `name=web-2`, `hostname=web-2`.
    *   `zabbix`: В `public-subnet-a`, с публичным IP.
    *   `elasticsearch`: В `private-subnet-a`, без публичного IP.
    *   `kibana`: В `public-subnet-a`, с публичным IP.
    *   Для всех ВМ указать SSH-ключ для доступа.

Создадим файл instance.tf в нем опишем виртуальные машины, которые планируем разворачивать в соответствии с планом и укажем в каких подсетях они будут работать. Буду создавать прерываемые машины с 2 Гб оперативной памяти и 2 ядрами процессора. Для авторизации буду использовать логин dudin и свой SSH ключ.

2.  **Создание балансировщика нагрузки (ALB):**
    *   **Target Group:** Включить `web-1` и `web-2` по FQDN (`web-1.ru-central1.internal`, `web-2.ru-central1.internal`).
    *   **Backend Group:** Нацелить на созданную Target Group. Настроить Health Check на `/` порт 80, протокол HTTP.
    *   **HTTP Router:** Создать, указав путь `/` на созданную Backend Group.
    *   **Application Load Balancer:** Разместить в `public-subnet-a`, присвоить публичный IP. Настроить Listener на порту 80, привязать к HTTP Router.

Приступим к созданию балансировщика нагрузки. Создадим файл alb.tf в котором опишем разделы:
*  Target Group
*  Backend Group
*  HTTP Router
*  Virtual Host
*  Application Load Balancer

Так же внесем изменения в файлы security_group.tf. Балансировщик не создавался и  ```terraform apply``` всегда заканчивался ошибкой связаной с HealtCheck. Попробовал некоторые варианты решений, рабочим оказался код 
```
  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080  
  }
```
predefined_target = "loadbalancer_healthchecks" автоматически разрешает все необходимые IP-диапазоны для Health Check от Yandex Cloud. После добавления этого блока, балансировщик был успешно создан. Осталось добавить в файл outputs.tf несколько строк для вывода информации о созданном балансировщике. 

Наглядно посмотрим на получившуюся инфраструктуру:
Dashboard Yandex Cloud
![Dashboard Yandex Cloud](https://github.com/noisy441/sys-diplom/blob/main/img/dashboard.png)

Сеть и подсети
![main-network](https://github.com/noisy441/sys-diplom/blob/main/img/main-network.png)

![subnet](https://github.com/noisy441/sys-diplom/blob/main/img/subnet.png)

Виртуальные машины
![VM](https://github.com/noisy441/sys-diplom/blob/main/img/vm.png)

Security group
![security-group](https://github.com/noisy441/sys-diplom/blob/main/img/security-group.png)

Балансировщик нагрузки.
![sbalancer](https://github.com/noisy441/sys-diplom/blob/main/img/balancer.png)

Target group
![target-group](https://github.com/noisy441/sys-diplom/blob/main/img/target-group.png)

Backend group
![backend-group](https://github.com/noisy441/sys-diplom/blob/main/img/backend-group.png)

HTTP-proxy
![http-proxy](https://github.com/noisy441/sys-diplom/blob/main/img/http-proxy.png)

### Этап 3: Базовая нстройка серверов (Ansible)

*   **Цель:** Установить и настроить базовое ПО на все ВМ.

1.  **Подготовка Ansible:**
    *   Создать `inventory.yml`, используя FQDN ВМ.
    *   Настроить подключение через Bastion Host с помощью `ansible.cfg` и `ProxyCommand` или развернуть и запускать Ansible непосредственно на `bastion`-хосте (как указано в задании, это проще).

Для реализации этой подзадачи создадим [inventory-fqdn.tf](inventory-fqdn.tf) и  шаблон [inventory.tpl](templates/inventory.tpl)это позволит нам собрать ansible инвентарь. Я буду использовать ProxyCommand для реализации подключения к машинам за Bastion, так как считаю это более удобным для себя решением. [ansible.cfg](ansible/ansible.cfg) дополню настройками ssh_connection.

Проверим что инфраструктура готова к настройке командой ``` ansible all -m ping```

2.  **Базовый Playbook:**
    *   Настроить системные параметры (timezone, updates).
    *   Установить и запустить `nginx` на `web-1` и `web-2`.
    *   Разместить статичный сайт на веб-серверах.

Буду использвать Ansible roles и в качестве первой роли создадим nginx. Создадим playbook [web.yml](ansible/web.yml) который будет запускать роль nginx на web_servers. В свою очередб роль будет устанавливать на web-1 и web-2 cthdth nginx и применять шаблоны для настройки сервера и для размещения страницы на веб сервере. После выполнения по адресу балансировщика станет открываться сайт который мы разместили. Так как в шаблоне HTML стртаницы есть динамические параметры, при обновлении страницы мы увидим, какой именно сервер сейчас отвечает.

Проверим наглядно, откроем страницу в браузере первый раз нам ответил сервер web-1
![web-1](https://github.com/noisy441/sys-diplom/blob/main/img/web-1.png)

Обновим страницу и увидим, что балансировщик обратился к web-2 и теперь намотвечает второй сервер
![web-2](https://github.com/noisy441/sys-diplom/blob/main/img/web-2.png)

Посмотрим на проверки состояния балансировщика. Видим, что оба сервера работают исправно.
![web-healt](https://github.com/noisy441/sys-diplom/blob/main/img/web-healt.png)

Проверим с помощью команды curl -v <публичный IP балансера>:80
Первое выполнение
![web-1](https://github.com/noisy441/sys-diplom/blob/main/img/curl1.png)

Второе выполнение
![web-2](https://github.com/noisy441/sys-diplom/blob/main/img/curl2.png)

### Этап 4: Внедрение мониторинга (Zabbix + Ansible)

*   **Цель:** Настроить мониторинг доступности и метрик всех систем.

1.  **Установка Zabbix Server (Ansible):**
    *   Playbook для ВМ `zabbix`: Установить Zabbix Server (Frontend + Server + PostgreSQL в одной ВМ).
    *   Настроить базу данных, веб-интерфейс.

Далее все сервисы я буду устанавливать с помощью ролей. Для сервера использую роль zabbix-server. Установлю Zabbix server, PostgreSQL в [main.yml](ansible/roles/zabbix-server/tasks/main.yml) опишу настройки сервисов, настройки базы данных, импорт схемы БД и другие параметры. Сервер будет доступен по адресу http://ip/zabbix логин и пароль будут стандартными. 

2.  **Установка и настройка Zabbix Agent 2 (Ansible):**
    *   Playbook для **всех** ВМ (включая сам Zabbix, Elasticsearch, Kibana).
    *   Настроить агентов на подключение к IP-адресу сервера Zabbix (`zabbix.ru-central1.internal`).
  
Роль для zabbix-agent будект выполнять установку агента на все виртуальные машины. Я передам агентам настройки для упрощения развертывания в частности буду использовать 
```
      HostMetadata=ubuntu
      HostMetadataItem=system.uname
```
Эти метаданные понадобятся мне, что бы быстро обнаружить агентов Zabbix сервером, а не добавлять каждую машину вручную.

3.  **Настройка Zabbix:**
    *   Через веб-интерфейс:
        *   Добавить все хосты.
        *   Создать дешборд с графиками по метрикам USE:
            *   **CPU:** 
            *   **RAM:** 
            *   **Диски:** 
            *   **Сеть:** 


Создам в разделе action - задачу для автоматического добавления машин с установленным zabbix agent.
Все машины обнаружились, агенты на них досnупны.
Создадим дашборд с требуемыми графиками.

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix1.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix2.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix3.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix4.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix5.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix6.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix7.png)

![zabbix](https://github.com/noisy441/sys-diplom/blob/main/img/zabbix8.png)

Мониторинг настроен


### Этап 5: Внедрение сбора и анализа логов (ELK Stack + Ansible)

*   **Цель:** Настроить централизованный сбор и визуализацию логов.

1.  **Установка Elasticsearch (Ansible):**
    *   Playbook для ВМ `elasticsearch`: Развернуть Elasticsearch

2.  **Установка Kibana (Ansible):**
    *   Playbook для ВМ `kibana`: Развернуть Kibana. Настроить подключение к `elasticsearch.ru-central1.internal:9200`.

3.  **Установка и настройка Filebeat (Ansible):**
    *   Playbook для ВМ `web-1` и `web-2`:
        *   Установить Filebeat.
        *   Настроить модуль `nginx`.
        *   Указать пути к `access.log` и `error.log`.
        *   Настроить вывод в `elasticsearch.ru-central1.internal:9200`.


Создадим три роли. Для Elasticsearch, Kibana и Filebeat.
Объединим запуск ролей в один файл [elk.yml](ansible/elk.yml) и закрепим запуск в файле [site.yml](ansible/site.yml) таким образом мы сможем запускать офин файл для разворачивания всего проекта. Установим Elasticsearch, Kibana и Filebeat


![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic0.img)

![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic1.img)

![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic2.img)

![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic3.img)

![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic4.img)

![elastic](https://github.com/noisy441/sys-diplom/blob/main/img/elastic5.img)

Сбор логов и их визуализация настроены. 

### Этап 6: Настройка резервного копирования (Terraform)

*   **Цель:** Обеспечить возможность восстановления данных.

1.  **Создание Snapshot Schedule:**
    *   В конфигурации Terraform для каждого загрузочного диска каждой ВМ создать ресурс `yandex_compute_snapshot_schedule`.
    *   Настроить ежедневное создание снепшотов.

Создадим [snapshot.tf](snapshot.tf) в котором опишем как и когда должны создаваться снимки. При создании инфраструктуры terraform применит наше правило к создаваемым машинам.

Snapshot
![snapshot](https://github.com/noisy441/sys-diplom/blob/main/img/snapshot.png)

### ИТОГИ

Работа выполнена. 

## Сайт доступен по адресу http://158.160.188.68/

## Zabbix доступен по адресу http://89.169.151.198/zabbix   
## логин Admin пароль zabbix

## Elastic доступeн по адресу http://89.169.141.131:5601/