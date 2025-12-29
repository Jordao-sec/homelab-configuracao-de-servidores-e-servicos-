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
