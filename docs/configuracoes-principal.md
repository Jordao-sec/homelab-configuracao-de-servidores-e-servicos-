### Estabelecer IP estático
Para definir um IP estático usaremos o netplan. Edite o arquivo com:
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```
No exemplo abaixo, usamos a interface `ens37`, que está conectada à rede interna. Remova o `dhcp4` dessa interface e adicione a configuração de endereço:
```
addresses:
- 172.16.0.1/24
```

Salve o arquivo e aplique as alterações:
```bash
sudo netplan apply
```

Verifique a configuração com:
```bash
ip a
```

### SSH
O serviço SSH permite acessar o servidor remotamente a partir de outros dispositivos na rede local ou remota.

#### Instalação
Instale o servidor SSH:
```bash
sudo apt update
sudo apt install openssh-server
```

#### Verificação
Verifique se o serviço está instalado e ativo:
```bash
sudo systemctl status ssh
```

Se não estiver ativo, inicie-o:
```bash
sudo systemctl start ssh
```

Para habilitar a inicialização automática:
```bash
sudo systemctl enable ssh
```

Verifique novamente:
```bash
sudo systemctl status ssh
```

#### Configuração
Recomenda-se ajustar algumas diretivas para aumentar a segurança. Edite o arquivo de configuração:
```bash
sudo nano /etc/ssh/sshd_config
```

Procure e altere (ou adicione) as seguintes diretivas conforme indicado:

- PermitRootLogin no  
  - Impede login direto como root (recomendado para segurança; reduz tentativas de força bruta ao usuário root).

- MaxAuthTries 3  
  - Número de tentativas de autenticação permitidas antes de encerrar a conexão; ajuda a reduzir ataques de força bruta.

- MaxSessions 3  
  - Número máximo de sessões simultâneas por conexão SSH; valores baixos são suficientes em ambientes domésticos.

Observação: as opções abaixo (autenticação por chave e por senha) devem ser usadas após configurar DHCP e o cliente enviar sua chave publica para o servidor:

- PubkeyAuthentication yes  
  - Habilita autenticação por chave pública (mais segura que senha).

- PasswordAuthentication no  
  - Desabilita autenticação por senha. Se for usar exclusivamente autenticação por chave pública, defina como `no` para reduzir a superfície de ataque.

Após salvar, reinicie o serviço:
```bash
sudo systemctl restart ssh
```

Teste a conexão a partir do cliente que possui a chave privada correspondente:
```bash
ssh usuario@ip_do_servidor
```

### DHCP
O serviço DHCP atribui endereços IP a dispositivos, além de informar o gateway e servidores DNS para acesso à rede e à Internet.

#### Instalação
```bash
sudo apt update
sudo apt install isc-dhcp-server
```

#### Configuração
Edite o arquivo que define a interface usada pelo serviço:
```bash
sudo nano /etc/default/isc-dhcp-server
```
Defina o nome da interface na variável `INTERFACESv4` (entre aspas) e salve o arquivo.

Faça um backup do arquivo principal de configuração:
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
```

Edite o arquivo de configuração:
```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Descomente a linha `authoritative` e adicione um bloco de exemplo para a sub-rede:
```bash
subnet 172.16.0.0 netmask 255.255.255.0 {
  range 172.16.0.3 172.16.0.254;        # Faixa de endereços a ser distribuída
  option routers 172.16.0.1;            # Endereço do gateway (servidor)
  option domain-name-servers 172.16.0.1, 172.16.0.2; # Servidores DNS
}
```

Verifique a sintaxe:
```bash
sudo dhcpd -t
```

Reinicie o serviço:
```bash
sudo systemctl restart isc-dhcp-server
```

Verifique o status:
```bash
sudo systemctl status isc-dhcp-server
```

Se houver problemas, cheque novamente a sintaxe:
```bash
sudo dhcpd -t
```

No cliente, teste reiniciando a interface de rede ou ligando a máquina; o cliente deve obter um IP automaticamente. No servidor, monitore os logs para confirmar a concessão:
```bash
sudo journalctl -u isc-dhcp-server -f
```

### DNS
O serviço DNS traduz nomes de domínio em endereços IP. Aqui configuraremos um servidor DNS autoritativo/resolver interno usando o BIND9.

#### Instalação
```bash
sudo apt update
sudo apt install bind9 bind9-doc bind9utils
```
- `bind9-doc`: documentação do BIND9.
- `bind9utils`: ferramentas auxiliares para diagnóstico e testes.

#### Configuração
Faça backup do arquivo de opções:
```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
```

Edite o arquivo de opções:
```bash
sudo nano /etc/bind/named.conf.options
```

Exemplo de configuração (insira abaixo da diretiva `directory "/var/cache/bind";`):
```bash
options {
    recursion yes;                  # Permitir resolver consultas usando outros servidores
    listen-on { 172.16.0.1; };      # Endereço em que o servidor vai escutar (ex.: interface interna)
    allow-transfer { none; };       # Desabilita transferência de zona por padrão

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
```

Edite o arquivo local de zonas:
```bash
sudo nano /etc/bind/named.conf.local
```

Adicione as zonas (exemplo):
```bash
zone "www.laboratorio.com" {
    type master;
    file "/etc/bind/zones/db.www.laboratorio.com";
    allow-transfer { 172.16.0.2; };  # Servidor secundário permitido (se houver)
};

zone "0.16.172.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.172.16.0";
    allow-transfer { 172.16.0.2; };
};
```

Crie o diretório de zones e copie o arquivo base:
```bash
sudo mkdir -p /etc/bind/zones
sudo cp /etc/bind/db.local /etc/bind/zones/db.www.laboratorio.com
```

Edite a zona direta:
```bash
sudo nano /etc/bind/zones/db.www.laboratorio.com
```
Substitua o registro padrão (`localhost. root.localhost.`) pelo SOA adequado, por exemplo:
```
ns1.www.laboratorio.com. admin.laboratorio.com. (
                              3   ; Serial
                              ... ; demais parâmetros (refresh, retry, expiry, minimum)
)
```
Atualize o serial para um número maior a cada alteração (ex.: 3) e, em seguida, ajuste os registros NS e A:
```
; Nameservers
    IN      NS      ns1.www.laboratorio.com.
    IN      NS      ns2.www.laboratorio.com.

; Endereços
ns1.www.laboratorio.com.  IN    A    172.16.0.1
ns2.www.laboratorio.com.  IN    A    172.16.0.2
```

Crie a zona reversa copiando o arquivo base:
```bash
sudo cp /etc/bind/db.127 /etc/bind/zones/db.172.16.0
sudo nano /etc/bind/zones/db.172.16.0
```
Altere o SOA(Informações adminstrativas sobre a zona DNS) e os registros PTR (ajuste o serial também):
```
ns1.www.laboratorio.com. admin.laboratorio.com. (
                              3   ; Serial
                              ... ; 
)

; Nameservers
    IN      NS      ns1.www.laboratorio.com.
    IN      NS      ns2.www.laboratorio.com.

; PTR records
1   IN      PTR     ns1.www.laboratorio.com.
2   IN      PTR     ns2.www.laboratorio.com.
```
(Observe: na zona 0.16.172.in-addr.arpa, o número `1` refere-se ao último octeto do IP 172.16.0.1.)

Verifique os arquivos de configuração e zonas:
```bash
sudo named-checkconf            # Não deve retornar nada se não houver erro
sudo named-checkzone www.laboratorio.com /etc/bind/zones/db.www.laboratorio.com
sudo named-checkzone 0.16.172.in-addr.arpa /etc/bind/zones/db.172.16.0
```

Reinicie o serviço:
```bash
sudo systemctl restart bind9
```

#### Encaminhamento (NAT) e acesso à Internet
Se o servidor deve permitir que cliente internos acessem a rede externa, habilite o encaminhamento de IP no kernel:
```bash
sudo nano /etc/sysctl.conf
```
Descomente:
```
net.ipv4.ip_forward=1
```
Aplique:
```bash
sudo sysctl -p
```

Adicione regras de NAT no iptables (exemplo):
```bash
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
sudo iptables -A FORWARD -i ens37 -o ens33 -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -i ens33 -o ens37 -j ACCEPT
```

Instale a persistência de regras:
```bash
sudo apt install iptables-persistent
```

Salve as regras:
```bash
sudo netfilter-persistent save
```

#### Testes no cliente
No cliente, teste resolução e conectividade:
```bash
ping nomedominio                # Ex.: ping ns1.www.laboratorio.com ou algum site da internet
nslookup nomedominio_ou_ip      # Ex.: nslookup ns1.www.laboratorio.com ou algum site da internet
```
### Docker
Docker é uma plataforma para criação e adminstração de serviços rodando em containers.

### Instalação
Para baixar o docker é necessario adcionar o repositório oficial do Docker no servidor, configurando a verificação criptográfica dos pacotes via GPG para garantir downloads seguros e autênticos. Use os seguintes comandos:
```bash
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```
Baixe o docker usando o seguinte comando:
```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
Este comando instala o Docker Engine, a interface de linha de comando, o runtime de containers (containerd) e plugins modernos como Buildx e Docker Compose, permitindo a criação, execução e orquestração de containers de forma segura e atualizada.

Verifique se o docker está funcioando usando:
```bash
sudo systemctl status docker
```
Teste o funcionamento do docker usando o seguinte comando:
```bash
sudo docker run hello-world
```bash

### Wordpress
O Wordpress é um sistema de gerenciamento de conteudo(CMS) para criar e gerenciar diversos tipos de sites (blogs, lojas virtuais, portfólios, portais)
### Instalação
Para instalar o Wordpress é necessário baixar usa imagem apartir de um arquivo compose, crie um diretorio para o Wordpress usando o comando:
```bash
sudo mkdir /home/servidor/wordpress
```
Crie um arquivo chamado compose.yaml usando o comando:
```bash
sudo nano /home/servidor/wordpress/compose.yaml
```
Coloque o seguinte no arquivo:
```
services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```
(Falta explicar sobre a instalação)
Suba o container usando o comando:
```bash
sudo docker compose up
```
Dentro do cliente tente acessar o Wordpress no navegador usando: http://ns1.www.laboratorio.com:8080 ou http://172.16.0.1:8080

### Portainer
O Portainer é uma ferramenta de gerenciamento de contêineres, muito útil para administrar contêineres por meio de um navegador web.

### Instalação 
Para baixar o Portainer, utilize o seguinte comando:o:
```bash
sudo curl -L https://downloads.portainer.io/ce-lts/portainer-compose.yaml -o portainer-compose.yaml
```
Para subir o Portainer, execute::
```
sudo docker compose -f portainer-compose.yaml up -d
```
Após a instalação, teste o Portainer acessando pelo navegador do cliente através de um dos endereços abaixo:
https://ns1.www.laboratorio.com:9443
https://172.16.0.1:9443

### Webmin
O Webmin é uma ferramenta de gerenciamento remoto de sistemas, ideal para usuários que não possuem muita experiência com Linux, pois oferece uma interface gráfica via navegador.

### Instalação
Para instalar o Webmin, é necessário primeiro adicionar o repositório oficial ao servidor utilizando o comando:
```bash
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
sudo sh webmin-setup-repo.sh
```
Após configurar o repositório, instale o Webmin com o comando:
```bash
sudo apt-get install webmin
```
Após a instalação, teste o Webmin acessando pelo navegador do cliente através de um dos endereços abaixo:
https://ns1.www.laboratorio.com:10000
https://172.16.0.1:10000

###
