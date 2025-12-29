### SSH
Serviço necessario para acessar remotamente o servidor apartir de outro dispositivo na mesma rede.

### Instalação
Para o servidor responder esse serviço é necessario baixa-lo, usamos: 
```bash 
sudo apt install openssh-server

### Verficação
Verifiquei se baixou tudo certo e se o serviço está rodando usando:
```bash
sudo systemctl status ssh

Pode notar que o serviço não está rodando por tanto vamos ativa-lo usando:
```bash
sudo systemctl start ssh

Verificamos se está rodando usando:
```bash
sudo systemctl status ssh

### Configuração
Após verificar é recomendavel fazer algumas configurações extras no proprio serviço de SSH para garantir mais segurança.
Irei editar o arquivo de configuração do SSH usando:
```bash
sudo nano /etc/ssh/sshd_config

Já dentro do arquivo vamos procurar as seguintes linhas: PermitRootLogin, MaxAuthTries, MaxSessions, PubkeyAuthetication e PasswordAuthetication.
Vamos descomentar todas elas, já que quando comentadas vão agir de forma padrão. E vamos definir os seguintes parametros para cada uma delas:

PermitRootLogin no Impede login direto como root (obrigatório para segurança – ataque comum é brute-force no root).

MaxAuthTries 3 Essa linha nos pergunta quantas tentativas são permitidas para autenticar com sucesso antes de derrubar a conexão, isso ajuda atrapalhar ataques de força bruta, por tanto vamos deixar em 3 tentativas.

MaxSessions 3 Essa linha nos diz quantas conexões SSH o servidor deve atender simultaniamente, não é necessario ter muitas conexões simultanêas então quanto menos melhor, vamos estabelecer 3.

Importânte/Observação: As ultimas duas opções só poderam ser configuradas após configuração do DHCP ou Definir um IP estático (Provisorio) e o cliente deve mandar sua chave publica para o servidor antes de bloquear a autenticação por senha, mas ambos estão sem conectividade um com o outro.

PubkeyAuthetication yes Habilita autenticação por chaves SSH (mais segura que senha). 

PasswordAuthetication no Essa linha nos pergunta se vamos permitir o uso de senha, para restringir ataques de força bruta vamos deixar em no já que é possível apenas dispositivos com a chave privada correta poderam se autenticar no servidor.

Salvamos o arquivo, para garantir que as alterações estão funcionando vamos usar:
```bash
sudo systemctl restart ssh 

Dai é só testar a configuração.
