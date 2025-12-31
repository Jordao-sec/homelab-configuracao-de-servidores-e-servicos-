### Estabelecer IP estático
Para estabelecer um ip estático vamos usar o netplan usando o comando: 
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```
Vamos para interface ens37, a qual está voltada para a rede interna, vamos remover o dhcp4 dela e adcionar: 

addresses:

        - 172.16.0.1/24

Salve o arquivo e use:

```bash
sudo netplan aplly
```
E verifique usando: 

```bash
ip a
```

### SSH
Serviço necessário para acessar remotamente o servidor a partir de outro dispositivo na rede local ou remota.

### Instalação
Para o servidor responder a esse serviço é necessário instalá‑lo. Usamos:
```bash
sudo apt install openssh-server
```

### Verificação
Verifique se o serviço foi instalado corretamente e se está ativo usando:
```bash
sudo systemctl status ssh
```

Se o serviço não estiver ativo, inicie‑o com:
```bash
sudo systemctl start ssh
```

Para garantir que o serviço inicie automaticamente na inicialização, você pode habilitá‑lo:
```bash
sudo systemctl enable ssh
```

Verifique novamente o status:
```bash
sudo systemctl status ssh
```

### Configuração
Após verificar a instalação, é recomendável fazer algumas configurações no serviço SSH para aumentar a segurança.

Edite o arquivo de configuração do SSH:
```bash
sudo nano /etc/ssh/sshd_config
```

Dentro do arquivo, procure as seguintes diretivas e ajuste conforme abaixo:

- PermitRootLogin no  
  - Impede login direto como root (recomendado para segurança; evita ataques de força bruta ao usuário root).

- MaxAuthTries 3  
  - Número de tentativas de autenticação permitidas antes de derrubar a conexão; ajuda a reduzir ataques de força bruta.

- MaxSessions 3  
  - Número máximo de sessões simultâneas por conexão SSH; não é necessário um valor alto em ambientes domésticos.

Importante/Observação: as últimas duas opções descritas abaixo (autenticação por chave e por senha) só poderão ser usadas corretamente após configurar um IP estático ou configurar o DHCP para garantir que o cliente já tenha enviado a sua chave pública ao servidor (arquivo `~/.ssh/authorized_keys` do usuário).

- PubkeyAuthentication yes  
  - Habilita autenticação por chave pública (mais segura que senha).

- PasswordAuthentication no  
  - Desabilita autenticação por senha. Se for usar somente autenticação por chave privada, defina como `no` para reduzir a superfície de ataque.

Depois de salvar o arquivo, reinicie o serviço para aplicar as alterações:
```bash
sudo systemctl restart ssh
```

Por fim, teste a conexão a partir do cliente que possui a chave privada correspondente (por exemplo: `ssh usuario@ip_do_servidor`) para garantir que tudo esteja funcionando.


### DHCP 
Esse serviço tem como objetivo entregar endereços ip para dispositivos endereço do gateway para acessar uma rede remota e o endereço do servidor DNS para resolução de nomes de sites e domínios.

### Instação

```bash
sudo apt install isc-dhcp-server
```
### Configuração

Antes de configurar derecione a interface que o serviço vai usar usando o seguinte comando:
```bash
sudo nano /etc/defaut/isc-dhcp-server
```
Após abrir o arquivo coloque o nome da interface entre "" na linha INTERFACESV4 e salve o arquivo

Vamos fazer um backup do arquvivo dchpd.conf usando o comando:
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup
```
Após vamos editar o arquivo usando:
```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Descomentei a linha de authoritative, e adcionei o seguinte no arquivo: 
```bash
subnet 172.16.0.0 netmask 255.255.255.0{ #Informa a subrede e seu tamanho
  range 172.16.0.3 172.16.0.254; #Diz a faixa de endereço que vai ser usada na distribuição
  option router 172.16.0.1; #Informa o endereço do gateway, no caso vai ser o proprio servidor
  option domain-name-server 172.16.0.1, 172.16.0.2; #Informa o endereço dos servidores DNS
}
```
Salve o arquivo, e verifique se não há erro de sintaxe usando: 
```bash
sudo dhcpd -t
```
Reinicie o serviço: 
```bash
sudo systemctl restart isc-dhcp-server
```

E verifique se está funcionando usando:
```bash
sudo systemctl status isc-dhcp-server
```
Caso não funcione verifique se há erros de sintaxe usando:
```bash
sudo dhcpd -t
```
Após isso realize o teste simplesmente ligando a maquina cliente, que vai pegar o endereço ip automaticamete
E use o seguinte comando no servidor para garantir que o cliente pegou o ip dele:
```bash
sudo journalctl -u isc-dhcp-server -f
```

### DNS
Esse serviço serve para transformar endereços de domino de sites em endereços ip, o servidor vai atuar como resolver DNS, ele vai resolver o nome de dominio na rede interna, caso ele não saiba qual enderço aquele dominio ele vai passar a solicitação a diante para um root sever na internet para o DNS do google (8.8.8.8, 8.8.4.4)

### Instalação
Para instalar o serviço use:
```bash
sudo apt install bind9 bind9-doc bind9utils
```
O bind9-doc é a documentação do software que inclui manuais, guias e informações detalhadas sobre como resolver problemas, já bind9utils baixa um conjunto de ferramentas para testar o funcionamento do DNS no servidor

### Configuração
Vamos editar o arquivo named.conf.options, mas antes vamos fazer uma copia de segurança usando:
```bash
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
```
Agora vamos abir o arquivo usando: 
```bash
sudo nano /etc/bind/named.conf.options
```
Vamos procurar a linha: directory "/var/cache/bin9"; e escrever as configurações embaixo dela  Você pode apagar todo o texto comentado (Linhas que tem "//" no começo)  nesse arquivo se desejar para deixar o arquivo menor e mais limpo. Adicionei o seguinte:
```bash
        recursion yes;                 # permite o sevidor passar as solicitações para outros servidores
        listen-on { 10.128.10.11; };   # endereço o qual o servidor vai receber as solicitações
        allow-transfer { none; };      # disabilita a transferência por zona por padrão 

        forwarders {
                8.8.8.8; # Endereço dos servidores DNS na internet
                8.8.4.4;
        };
```

Agora vamos abir o seguinte arquivo:
```bash
sudo nano /etc/bind/named.conf.local
```
Adcionei o seguinte em qualquer parte do arquivo:
```bash
zone "www.laboratorio.com" #Nome da zona {
    type master; #Como o servidor vai atuar
    file "/etc/bind/zones/db.www.laboratorio.com"; # Arquivo da zona
    allow-transfer { 172.16.0.2; };  # Endereço do servidor secundario que vai receber as instruções
};

zone "0.16.172.in-addr.arpa" #Resolução inversa transformar ip em nome de domínio {
    type master;
    file "/etc/bind/zones/db.172.16.0";  # 172.16.0.0/24 subrede
    allow-transfer { 172.16.0.2; };  # Endereço do servidor secundario que vai receber as intruções
};
```
Salve o arquivo, vamos criar um diretorio zones usando:
```bash
sudo mkdir /etc/bind/zones
```
Vamos copiar o arquivo db.local que tem uma base pronta para o arquivo db.www.laboratorio.com usando o comando:
```bash
sudo cp /etc/bind/db.local /etc/bind/zones/db.www.laboratorio.com
```
Vamos editar o arquivo usando:
```bash
sudo nano /etc/bind/zones/db.www.laboratorio.com
```
Procure a linha que está escrito localhost. root.localhost. e subistitui por:
```bash
ns1.www.laboratorio.com. admin.laboratorio.com. (
                              3         ; Serial

```
Não se esqueça de trocar o valor do serial para 3
Apagei as ultimas 3 linhas do arquivo e subistitui por:
```
;Nome dos servidores DNS 
    IN      NS      ns1.www.laboratorio.com.
    IN      NS      ns2.www.laboratorio.com.

;Endereço dos dominios 
ns1.www.laboratorio.com.          IN      A       172.16.0.1
ns2.www.laboratorio.com.          IN      A       172.16.0.2
```
Vamos criar a zona reversa para transformar o ip em dominio, para isso vamos copiar o arquivo base db.127 usando o seguinte comando:
```bash
sudo cp /etc/bind/db.127 /etc/bind/zones/db.172.16.0
```
Vamos editar o arquivo db.172.16.0 usando: 
```bash
sudo nano /etc/bind/zones/db.172.16.0
```
Procure a linha que está escrito localhost. root.localhost. e subistitui por:
```bash
ns1.www.laboratorio.com. admin.laboratorio.com. (
                              3         ; Serial

```
Não se esqueça de trocar o valor do serial para 3
Apague as duas ultimas linhas e subistitui por: 
```bash
;Nome dos servidores DNS
      IN      NS      ns1.www.laboratorio.com.
      IN      NS      ns2.www.laboratorio.com.

;Endereço dos dominios  
16.0.1   IN      PTR     ns1.www.laboratorio.com.              
16.0.2   IN      PTR     ns2.www.laboratorio.com.
```
Verifiquei se há algum erro nos arquivos usando os comandos: 
```bash
sudo named-checkconf #Não deve aparecer nada após usar o comando
sudo named-checkzone www.laboratorio.com /etc/bind/zones/db.www.laboratorio.com #Deve aparecer OK
sudo named-checkzone 0.16.172.in-addr.arpa /etc/bind/zones/db.172.16.0 #Deve aparecer OK
```
Reinicie o serviço usando:
```bash
sudo systemctl restart bind9
```
Antes de realizar os teste no cliente é preciso permitir que o servidor consiga fazer NAT para permite que o cliente consiga acessar a internet, que por padrão ele não faz.
Foi habilitado o IP Forward no kernel Linux para permitir que o servidor atue como roteador, encaminhando pacotes entre a interface da rede interna e a interface conectada à internet. É preciso editar o seguinte arquivo:
```bash
sudo nano /etc/sysctl.conf
```
Descomentar a linha net.ipv4.ip_forward=1 e salvar o arquivo.
Depois crie as seguintes regras no iptables:
```bash
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE # Permite que os endereços IP privados da rede interna tenham acesso à rede externa e posteriomene a internet através da interface externa do servidor.
iptables -A FORWARD -i ens37 -o ens33 -j ACCEPT #Permite pacotes que venham da rede interna vão para a rede externa
```
Instale o seguinte:
```bash
sudo apt install iptables-persistent #Deixa as regras do iptables persistentes
```
Salve as regras usando:
```bash
sudo netfilter-persistent save
```
Agora realize os testes no cliente usando os seguintes comandos:
```bash
ping #Nome de Domínio
nslookup #Endereço ip ou nome de domínio
```
