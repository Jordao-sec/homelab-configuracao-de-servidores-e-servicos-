### Estabelecer IP estático

Para definir um IP estático no servidor secundario usaremos o netplan. Edite o arquivo com:
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Na interface ens37, que está conectada à rede interna. Adicione a configuração de endereço:
```
ens37
  addresses:
    - 172.16.0.2/24
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
Instalação

Instale o servidor SSH:
```bash
sudo apt install openssh-server
```
### Verificação

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
No cliente crie o par de chaves RSA de 2048 bits usando o comando:
```bash
ssh-keygen -t rsa -b 2048 -C "Homelab"
```
Envie a chave pública para o servidor usando o comando:
```bash
ssh-copy-id homelab.pub servidor@172.16.0.2
```

### Configuração

Recomenda-se ajustar algumas diretivas para aumentar a segurança. Edite o arquivo de configuração:
```bash
sudo nano /etc/ssh/sshd_config
```
Procure e altere as seguintes diretivas conforme indicado:

    PermitRootLogin no
        Impede login direto como root (recomendado para segurança; reduz tentativas de força bruta ao usuário root).

    MaxAuthTries 3
        Número de tentativas de autenticação permitidas antes de encerrar a conexão; ajuda a reduzir ataques de força bruta.

    MaxSessions 3
        Número máximo de sessões simultâneas por conexão SSH.

    PubkeyAuthentication yes
        Habilita autenticação por chave pública (mais segura que senha).

    PasswordAuthentication no
        Desabilita autenticação por senha. Se for usar exclusivamente autenticação por chave pública, defina como no para reduzir a superfície de ataque. 
*Observação: A autenticação por senha deve ser permitida realizar o teste do fail2ban futuramente.

Após salvar, reinicie o serviço:
```bash
sudo systemctl restart ssh
```
Teste a conexão a partir do cliente que possui a chave privada correspondente:
```bash
ssh -i homelab servidor@172.16.0.2  
```bash
Note que se você tentar se conectar da forma padrão:
```bash
ssh servidor@172.16.0.2
```
Vai dar acesso negado.

### DNS

### Instalação
Para configurar o DNS no servidor secundario é necessário baixar o bind9 usando o seguinte comando:
```bash
sudo apt install bind9 bind9-doc bind9utils
```
bind9-doc: documentação do BIND9.
bind9utils: ferramentas auxiliares para diagnóstico e testes.

### Configuração

Faça backup do arquivo de opções:
```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
```
Edite o arquivo de opções:
```bash
sudo nano /etc/bind/named.conf.options
```
Insira o seguinte abaixo da linha directory "/var/cache/bind":
```
options {
    recursion yes;                  # Permitir resolver consultas usando outros servidores
    listen-on { 172.16.0.2; };      # Endereço em que o servidor vai escutar (ex.: interface interna)
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
Adicione as zonas que o servidor secundario vai busacar do servidor primario:
```
zone "www.laboratorio.com" {
    type slave;
    file "db.www.laboratorio.com";
    allow-transfer { 172.16.0.1; };  # Servidor primario
};

zone "0.16.172.in-addr.arpa" {
    type master;
    file "db.172.16.0";
    masters { 172.16.0.1; }; Servidor primário
};
```
Verifique se há algum erro usando o comando:
```bash
sudo named-checkconf
```
Reinicie o serviço:
```bash
sudo systemctl restart bind9
```
### Encaminhamento (NAT) e acesso à Internet

Se o servidor deve permitir que cliente internos acessem a rede externa(Internet), habilite o encaminhamento de IP no arquivo sysctl.conf usando o seguinte comando:
```bash
sudo nano /etc/sysctl.conf
```
Descomente:
```
net.ipv4.ip_forward=1
```
Salve o arquivo e aplique:
```bash
sudo sysctl -p
```
Adicione regras de NAT no iptables:
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
### Teste
No servidor primário desligue o bind9 usando o seguinte comando:
```bash
sudo systemctl stop bind9
```
No cliente, teste resolução e conectividade:
```bash
ping nomedominio                # Ex.: ping ns1.www.laboratorio.com ou algum site da internet
nslookup nomedominio_ou_ip      # Ex.: nslookup ns1.www.laboratorio.com ou algum site da internet
```
### NTP

### Instalação
Para instalar o NTP use o comando:
```bash
sudo apt install chrony
```
### Configuração
Para configurar o NTP abra o arquivo chrony.conf. Usando o seguinte comando:
```bash
sudo nano /etc/chrony/chrony.conf
```
Apague substitua os servidores do ubuntu pelo servidor primário e use o endereço da interface interna para sincronizar o relógio. Da seguinte forma :
```
server 172.16.0.1 iburst
bindaddress 172.16.0.2
```
Reinicie o serviço usando:
```bash
sudo systemctl restart bind9
```
### Teste 
Para verficar o funcionamento do NTP basta usar os seguintes comandos: 
```bash
chronyc tracking
chronyc sources
```
### Webmin

### Instalação

Para instalar o Webmin, é necessário primeiro adicionar o repositório oficial ao servidor utilizando o comando:
```bash
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
sudo sh webmin-setup-repo.sh
```
Após configurar o repositório, instale o Webmin com o comando:
```bash
sudo apt-get install --install-recommends webmin usermin
```
Após a instalação, teste o Webmin acessando pelo navegador do cliente através de um dos endereços abaixo: https://ns1.www.laboratorio.com:10000 https://172.16.0.1:10000 Para logar basta apenas o nome de usario e senha do proprio servidor.

### Iptables

### Configuração
Para configurar o iptables use o script deste repositorio localizado em scripts/firewall_secundario.sh. Ele configura:

Políticas restritivas (DROP) por padrão.

Libera as portas dos serviços.

Roteamento entre as interfaces ens37 (LAN) e ens33 (WAN).

Para executar use o comando:
```bash
sudo chmod +x firewall_secundario.sh
sudo ./firewall_secundario.sh
```
Verifique as regras usando o comando:
```bash
sudo iptables -L -v -n
```
No cliente faça as os mesmos testes do DNS para verificar se está fucnionando e veja todas as portas abertas com o nmap usando o comando:
```bash
sudo nmap -sT -sU -p- 172.16.0.2
```
