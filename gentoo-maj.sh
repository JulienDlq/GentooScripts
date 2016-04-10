#!/bin/bash

. ./init

#----------
# VARIABLES
#----------

MESSAGE_OK="Tout s'est bien passé. ;-)"
MESSAGE_KO="Il y a eu un soucis... :-S"
MESSAGE_NA="Il y n'y a pas de mise à jour à faire... :-O"
MESSAGE_FATAL="Il y a eu une erreur fatale non gérée... x.x"
JOURNAL_DOSSIER="${HOME}/Log"
JOURNAL_DATE=$(date +%F-%H%M%S).log
FORCE=0

mkdir -p $JOURNAL_DOSSIER

#----------
# FONCTIONS
#----------
function initialiseJournalScript
{
	FONCTION=$1
	JOURNAL="${JOURNAL_DOSSIER}/$JOURNAL_DATE"
	DATE="$(date +"%F %T")"
	echo "$DATE ($FONCTION) :: DEBUT"
	echo "$DATE ($FONCTION) :: DEBUT" >> $JOURNAL
}

function finaliseJournalScript
{
	FONCTION=$1
	JOURNAL="${JOURNAL_DOSSIER}/$JOURNAL_DATE"
	DATE="$(date +"%F %T")"
	echo "$DATE ($FONCTION) :: FIN"
	echo "$DATE ($FONCTION) :: FIN" >> $JOURNAL
}

function messageJournalScript
{
	RESULTAT=$1
	FONCTION=$2
	JOURNAL="${JOURNAL_DOSSIER}/$JOURNAL_DATE"
	DATE="$(date +"%F %T")"
	if [[ $RESULTAT -eq 0 ]]
	then
		echo "$DATE ($FONCTION) :: $MESSAGE_OK"
		echo "$DATE ($FONCTION) :: $MESSAGE_OK" >> $JOURNAL
	elif [[ $RESULTAT -eq 1 && $FONCTION != "eix-diff" ]]
	then
		echo "$DATE ($FONCTION) :: $MESSAGE_KO"
		echo "$DATE ($FONCTION) :: $MESSAGE_KO" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 1
	elif [[ $RESULTAT -eq 1 && $FONCTION == "eix-diff" ]]
	then
		echo "$DATE ($FONCTION) :: $MESSAGE_NA"
		echo "$DATE ($FONCTION) :: $MESSAGE_NA" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 0
	else
		echo "$DATE ($FONCTION) :: $MESSAGE_FATAL"
		echo "$DATE ($FONCTION) :: $MESSAGE_FATAL" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 2
	fi
}


function rafraichissementEnvironnement
{
	FONCTION="env-update"
	initialiseJournalScript $FONCTION
	env-update
	RESULTAT=$?
	messageJournalScript $RESULTAT $FONCTION
	finaliseJournalScript $FONCTION

	FONCTION="source-etc-profile"
	initialiseJournalScript $FONCTION
	source /etc/profile
	RESULTAT=$?
	messageJournalScript $RESULTAT $FONCTION
	finaliseJournalScript $FONCTION
}

#------------
# MISE A JOUR
#------------

case $1 in
-sync)
	FONCTION="eix-sync"
	initialiseJournalScript $FONCTION
	eix-sync
	RESULTAT=$?
	messageJournalScript $RESULTAT $FONCTION
	finaliseJournalScript $FONCTION
	rafraichissementEnvironnement
;;
-nosync)
;;
*|"")
	echo "Utilisation : ./$(basename $0) <-sync|-nosync> [-force]"
	echo "-sync : synchronise l'arbre portage et la recherche eix avant la mise à jour."
	echo "-nosync : lance la mise à jour sans synchroniser l'arbre portage et la recherche eix."
	echo "-force : force la mise à jour même s'il n'y a pas d'update dans eix-diff"
	exit 0
;;
esac

case $2 in
-force)
	FONCTION="force"
	initialiseJournalScript $FONCTION
	FORCE=1
	RESULTAT=$?
        messageJournalScript $RESULTAT $FONCTION
        finaliseJournalScript $FONCTION
;;
*|"")
;;
esac

if [[ FORCE -eq 0 ]]
then
	FONCTION="eix-diff"
	initialiseJournalScript $FONCTION
	eix-diff | grep -E '\[.*U.*]'
	RESULTAT=$?
	messageJournalScript $RESULTAT $FONCTION
	finaliseJournalScript $FONCTION
	rafraichissementEnvironnement
fi

FONCTION="emerge-world"
initialiseJournalScript $FONCTION
emerge -vNuD --with-bdeps=y @world
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="emerge-preserved-rebuild"
initialiseJournalScript $FONCTION
emerge -v @preserved-rebuild
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="emerge-c"
initialiseJournalScript $FONCTION
emerge -vc
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="preserved-rebuild"
initialiseJournalScript $FONCTION
emerge -v @preserved-rebuild
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="revdep-rebuild"
initialiseJournalScript $FONCTION
revdep-rebuild
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="etc-update"
initialiseJournalScript $FONCTION
etc-update
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

FONCTION="eclean-distfiles"
initialiseJournalScript $FONCTION
eclean -v distfiles
RESULTAT=$?
messageJournalScript $RESULTAT $FONCTION
finaliseJournalScript $FONCTION
rafraichissementEnvironnement

exit 0
