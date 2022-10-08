#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Toute la suite va nécessiter des droits d'admin
verificationAdmin

# Variables
compilation_active=0
compilation_en_cours=''
pid_tail=0

while true
do
	# Récupération du paquet en cours de compilation
	# (uniq est ajouté pour éviter un bug entre portage et genlop)
	compilation_en_cours=$(genlop -c | grep ' \* ' | sed -e 's/ \* //' -e 's/ $//' | uniq )

	# Phase d'Attente ou de Démarrage
	if [[ $compilation_active -eq 0 ]]
	then
		# Sous-Phase Compilation Démarrée
		if [[ ! -z "$compilation_en_cours" ]]
		then
			# Lancement du tail correspondant
			( grc tail -F /var/tmp/portage/${compilation_en_cours}/temp/build.log ) &
			# Récupération du PID
			pid_tail=$!
			# Rendre la compilation active
			compilation_active=1
		fi
	# Phase En Cours
	else
		# Sous-Phase Compilation Terminée
		if [[ -z "$compilation_en_cours" ]]
		then
			# Rendre la compilation inactive
			compilation_active=0
			# Arrêt du tail correspondant
			kill -TERM $pid_tail
			# Réinitialisation du PID
			pid_tail=0
			# Aérer la console en cas de nouvelle compilation
			echo
		fi
	fi
	sleep 1
done 2>/dev/null

exit 0
