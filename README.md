# Apache Projects Manager - APM

Uma simples aplicação para praticar o shell script e também ajudar no desenvolvimento com Apache.

## Funcionalidades

### Criar novos projetos

Com o comando `./apm.sh create <nome do projeto>`, você consegue criar um novo projeto, sendo criado o arquivo `.conf` dentro de `/etc/apache2/sites-available` e a pasta do projeto em si dentro de `/var/www`.

### Deletar projetos existentes

Com o comando `./apm.sh delete <nome do projeto>`, você consegue deletar algum projeto já existente, sendo removido o arquivo de configuração e a pasta do projeto. Além disso, há uma confirmação se deseja mesmo deleta-lo.

### Iniciar e parar de rodar um projeto

Com os comandos `./apm.sh start <nome do projeto>` e `./apm.sh stop <nome do projeto>`, você consegue iniciar e parar de rodar um projeto respectivamente. É permitido apenas que 1 projeto rode por vez, então se um projeto já esteja rodando e deseja iniciar outro, o que estava rodando é parado e o outro é iniciado.

### Listar todos projetos

Com o comando `./apm.sh list`, é listado todos os projetos e ver qual está rodando no momento.

### Reiniciar o serviço do apache 

Com o comando `./apm.sh restart`, o serviço do apache é reiniciado.