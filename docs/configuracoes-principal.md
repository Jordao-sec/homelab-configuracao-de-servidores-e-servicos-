### SSH
Serviço necessario para acessar remotamente o servidor apartir de outro dispositivo na mesma rede.

### Instalação
Para o servidor responder esse serviço é necessario baixa-lo, usamos: 
sudo apt install openssh-server

### Verficação
Verifiquei se baixou tudo certo e se o serviço está rodando usando: 
sudo systemctl status ssh

### Configuração
Após verificar é recomendavel fazer algumas configurações extras no proprio serviço de SSH para garantir mais segurança.
Irei editar o arquivo de configuração do SSH usando:
sudo nano /etc/ssh/sshd.config

Já dentro do arquivo vamos procurar as seguintes linhas: 
