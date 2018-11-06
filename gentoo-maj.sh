#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-maj-config

#----------
# VARIABLES
#----------

MESSAGE_OK="Tout s'est bien passé. ;-)"
MESSAGE_KO="Il y a eu un soucis... :-S"
MESSAGE_NA="Il y n'y a pas de mise à jour à faire... :-O"
MESSAGE_FATAL="Il y a eu une erreur fatale non gérée... x.x"
JOURNAL_DOSSIER="/var/log/gentooscripts"
JOURNAL_DATE=$(date +%F-%H%M%S).log
FORCE=0

if [[ $SETVERBOSE -eq 1 ]]
then
	VERBOSE="--verbose"
else
	VERBOSE=""
fi
if [[ $SETQUIET -eq 1 ]]
then
	QUIET="--quiet-build y"
else
	QUIET="--quiet-build n"
fi

mkdir -p $JOURNAL_DOSSIER

#----------
# FONCTIONS
#----------
function lancer
{
	FONCTION=$1
	COMMANDE=$2
	RAFRAICHIR=$3
	initialiseJournalScript $FONCTION
	eval $COMMANDE
	RESULTAT=$?
	messageJournalScript $RESULTAT $FONCTION
	finaliseJournalScript $FONCTION
	if eval $RAFRAICHIR
	then
		rafraichissementEnvironnement
	fi
}

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
	COMMANDE="env-update"
	lancer $FONCTION "$COMMANDE" false

	FONCTION="source-etc-profile"
	COMMANDE="source /etc/profile"
	lancer $FONCTION "$COMMANDE" false
}

#------------
# MISE A JOUR
#------------

case $1 in
-sync)
	FONCTION="layman-S"
	COMMANDE="layman $VERBOSE -S"
	lancer $FONCTION "$COMMANDE" true

	FONCTION="eix-sync"
	COMMANDE="eix-sync"
	lancer $FONCTION "$COMMANDE" true
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
	COMMANDE="eix-diff | grep -E '\[.*U.*]'"
	lancer $FONCTION "$COMMANDE" true
fi

FONCTION="emerge-world--update"
COMMANDE="emerge $VERBOSE $QUIET -u --with-bdeps=y @world"
lancer $FONCTION "$COMMANDE" true

FONCTION="emerge-world--update-new-use)"
COMMANDE="emerge $VERBOSE $QUIET -Nu --with-bdeps=y @world"
lancer $FONCTION "$COMMANDE" true

FONCTION="emerge-world--update-new-use-deep)"
COMMANDE="emerge $VERBOSE $QUIET -NuD --with-bdeps=y @world"
lancer $FONCTION "$COMMANDE" true

FONCTION="emerge-preserved-rebuild"
COMMANDE="emerge $VERBOSE $QUIET @preserved-rebuild"
lancer $FONCTION "$COMMANDE" true

FONCTION="emerge-c"
COMMANDE="emerge $VERBOSE $QUIET -c"
lancer $FONCTION "$COMMANDE" true

FONCTION="emerge-preserved-rebuild"
COMMANDE="emerge $VERBOSE $QUIET @preserved-rebuild"
lancer $FONCTION "$COMMANDE" true

FONCTION="revdep-rebuild"
COMMANDE="revdep-rebuild -- $VERBOSE $QUIET"
lancer $FONCTION "$COMMANDE" true

FONCTION="etc-update"
COMMANDE="etc-update $VERBOSE"
lancer $FONCTION "$COMMANDE" true

FONCTION="eclean-distfiles"
COMMANDE="eclean -v distfiles"
lancer $FONCTION "$COMMANDE" true

exit 0
