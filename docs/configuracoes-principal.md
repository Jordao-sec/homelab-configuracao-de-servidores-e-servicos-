### SSH
Serviço necessário para acessar remotamente o servidor a partir de outro dispositivo, geralmente pela mesma rede local (ou pela internet, se houver encaminhamento/roteamento adequado).

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

Dentro do arquivo, procure as seguintes diretivas e ajuste conforme abaixo (remova o comentário caso estejam comentadas, pois quando comentadas usam o comportamento padrão):

- PermitRootLogin no  
  - Impede login direto como root (recomendado para segurança; evita ataques de força bruta ao usuário root).

- MaxAuthTries 3  
  - Número de tentativas de autenticação permitidas antes de derrubar a conexão; ajuda a reduzir ataques de força bruta.

- MaxSessions 3  
  - Número máximo de sessões simultâneas por conexão SSH; não é necessário um valor alto em ambientes domésticos.

Importante/Observação: as últimas duas opções descritas abaixo (autenticação por chave e por senha) só poderão ser usadas corretamente após configurar um IP estático ou uma reserva DHCP (se necessário) e garantir que o cliente já tenha enviado a sua chave pública ao servidor (arquivo `~/.ssh/authorized_keys` do usuário).

- PubkeyAuthentication yes  
  - Habilita autenticação por chave pública (mais segura que senha).

- PasswordAuthentication no  
  - Desabilita autenticação por senha. Se for usar somente autenticação por chave privada, defina como `no` para reduzir a superfície de ataque.

Depois de salvar o arquivo, reinicie o serviço para aplicar as alterações:
```bash
sudo systemctl restart ssh
```

Por fim, teste a conexão a partir do cliente que possui a chave privada correspondente (por exemplo: `ssh usuario@ip_do_servidor`) para garantir que tudo esteja funcionando.
