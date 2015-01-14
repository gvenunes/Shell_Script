#!/bin/bash
###################################################################################
#     Script de controle do loader                                                #
#     Desenvolvido por:     Giovane                                               #
#                           SILRO                                                 #
#     Criado:               13 / 01 / 2015                                        #
#     Ult. Alteracao:       13 / 01 / 2015                                        #
#     Colaboradores: Giovane Nunes Carillo                                        #
###################################################################################

#########################################################################################################
#       Configuracao para fazer debug - SHELL                                                           #
#-v: Mostra a linha de entrada que esta sendo lida pelo shell.                                          #
#-x: Mostra as variaveis ja substituidas, comandos e seus argumentos no momento de sua execucao.        #
# para configurar o debug set -vx : Ativa o modo debug completo | set +vx: Desativa o modo debug        #
#########################################################################################################

###################################################################################
#     Definicao de Variaveis                                                      #
#     Criado:               13 / 01 / 2015                                        #
#     Ult. Alteracao:       13 / 01 / 2015                                        #
###################################################################################

export LC_ALL="pt_BR.ISO-8859-1"

USEREXEC="loader"
JBOSS_HOME="/home/jboss"
NAMEPROCESS="contabatch_loader"
HOMEPROCESS="$JBOSS_HOME/$NAMEPROCESS"
PID_FILE="/var/run/$NAMEPROCESS.pid"
LOGPROCESS="$HOMEPROCESS/$NAMEPROCESS.log"
CLASSPATH="$HOMEPROCESS/contabatch-loader_lib"
CONTAUPLOAD="$HOMEPROCESS/conf/contaupload.xml"
PGREP_STRING="$HOMEPROCESS/contabatch-loader.jar"

#
XM="-Xms256m -Xmx512m"
START_CMD="java $XM -cp $CLASSPATH -jar $PGREP_STRING -x $CONTAUPLOAD"
#
###Nao Altere nada alem das variaveis acima###

status_success="\033[;32m [OK] \033[m"
status_fail="\033[;31m [FAILED] \033[m"

log_success_msg() {
  echo -e "$* 		$status_success"
  logger "$_"
}

log_failure_msg() {
  echo -e "$* 		$status_fail"
  logger "$_"
}

start_daemon() {
  eval "$*"
}

check_proc() {
  pgrep -u $USEREXEC -f $PGREP_STRING >/dev/null
}

killproc() {
  pkill -u $USEREXEC -f $PGREP_STRING 
}

CUR_USER=$(whoami)

start_script() {
  check_proc
  if [ $? -eq 0 ]; then
    log_success_msg "$NAMEPROCESS ja esta em execucao!!!." 
    exit 0
  fi

	if [ "${CUR_USER}" = "$USEREXEC" ] ; then
		cd $HOMEPROCESS
		start_daemon "$START_CMD &> $LOGPROCESS &"
	else
		#EXEC="su - $USEREXEC -c "
		cd $HOMEPROCESS
		su - $USEREXEC -c  "$START_CMD &> $LOGPROCESS &"
	fi

  # aguardar por um tempo para verificar se o programa responde
  sleep 5
  check_proc
  if [ $? -eq 0 ]; then
    log_success_msg "Iniciado $NAMEPROCESS."
  else
    log_failure_msg "Erro ao Iniciar $NAMEPROCESS."
    exit -1
  fi
}

stop_script() {
  check_proc
  if [ $? -eq 0 ]; then
    killproc -p $PID_FILE >/dev/null

    # Certificando que o programa foi encerrado antes de iniciar
    until [ $? -ne 0 ]; do
      sleep 1
      check_proc
    done

    check_proc
    if [ $? -eq 0 ]; then
      log_failure_msg "Erro ao Parar $NAME."
      exit -1
    else
      log_success_msg "Encerrado $NAME."
    fi
  else
    log_failure_msg "$NAME nao esta em execucao"
  fi
}

check_status() {
  check_proc
  if [ $? -eq 0 ]; then
    log_success_msg "$NAMEPROCESS em Execucao."
  else
    log_failure_msg "$NAMEPROCESS foi Encerrado."
    exit -1
  fi
}

check_log() {
  check_proc
  if [ $? -eq 0 ]; then
    log_success_msg "Lendo $NAMEPROCESS."
    	cat $LOGPROCESS | less
  else
    log_failure_msg "Erro ao ler log do $NAMEPROCESS, o processo nao esta sendo executado"
    exit -1
  fi
}

case "$1" in
  start)
    start_script
    ;;
  stop)
    stop_script
    ;;
  restart)
    stop_script
    start_script
    ;;
  status)
    check_status
    ;;
  log)
  	check_log
  	;;  
  *)
    echo "Usage: $0 {start|stop|restart|log|status}"
    exit 1
esac

exit 0
 
