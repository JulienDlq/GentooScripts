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


declare -A MESSAGE
MESSAGE=(
	['OK']="Tout s'est bien passé. ;-)"
	['KO']="Il y a eu un soucis... :-S"
	['NA']="Il y n'y a pas de mise à jour à faire... :-O"
	['FATAL']="Il y a eu une erreur fatale non gérée... x.x"
)

declare -A JOURNAL
JOURNAL=(
	['DOSSIER']="/var/log/gentooscripts"
	['DATE']=$(date +%F-%H%M%S).log
)

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

declare -a LISTE_DE_MAJ
LISTEDEMAJ=(
	ESU
	ESUNU
	ESUNUD
	EPR
	EWU
	EWUNU
	EWUNUD
	EPR
	EC
	EPR
	RR
	EU
	ED
)

declare -A LS
LS=(
	['FONCTION']="layman-S"
	['COMMANDE']="layman $VERBOSE -S"
)
declare -A ES
ES=(
	['FONCTION']="eix-sync"
	['COMMANDE']="eix-sync"
)
declare -A EDIF
EDIF=(
	['FONCTION']="eix-diff"
	['COMMANDE']="eix-diff | grep -E '\[.*U.*]'"
)
declare -A ENVU
ENVU=(
	['FONCTION']="env-update"
	['COMMANDE']="env-update"
)
declare -A SEP
SEP=(
	['FONCTION']="source-etc-profile"
	['COMMANDE']="source /etc/profile"
)
declare -A ESU
ESU=(
	['FONCTION']="emerge-system--update"
	['COMMANDE']="emerge $VERBOSE $QUIET -u --with-bdeps=y @system"
)
declare -A ESUNU
ESUNU=(
	['FONCTION']="emerge-system--update-new-use"
	['COMMANDE']="emerge $VERBOSE $QUIET -Nu --with-bdeps=y @system"
)
declare -A ESUNUD
ESUNUD=(
	['FONCTION']="emerge-system--update-new-use-deep"
	['COMMANDE']="emerge $VERBOSE $QUIET -NuD --with-bdeps=y @system"
)
declare -A EWU
EWU=(
	['FONCTION']="emerge-world--update"
	['COMMANDE']="emerge $VERBOSE $QUIET -u --with-bdeps=y @world"
)
declare -A EWUNU
EWUNU=(
	['FONCTION']="emerge-world--update-new-use"
	['COMMANDE']="emerge $VERBOSE $QUIET -Nu --with-bdeps=y @world"
)
declare -A EWUNUD
EWUNUD=(
	['FONCTION']="emerge-world--update-new-use-deep"
	['COMMANDE']="emerge $VERBOSE $QUIET -NuD --with-bdeps=y @world"
)
declare -A EPR
EPR=(
	['FONCTION']="emerge-preserved-rebuild"
	['COMMANDE']="emerge $VERBOSE $QUIET @preserved-rebuild"
)
declare -A EC
EC=(
	['FONCTION']="emerge-c"
	['COMMANDE']="emerge $VERBOSE $QUIET -c"
)
declare -A RR
RR=(
	['FONCTION']="revdep-rebuild"
	['COMMANDE']="revdep-rebuild -- $VERBOSE $QUIET"
)
declare -A EU
EU=(
	['FONCTION']="etc-update"
	['COMMANDE']="etc-update $VERBOSE"
)
declare -A ED
ED=(
	['FONCTION']="eclean-distfiles"
	['COMMANDE']="eclean -v distfiles"
)

mkdir -p ${JOURNAL['DOSSIER']}

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
	JOURNAL="${JOURNAL['DOSSIER']}/${JOURNAL['DATE']}"
	DATE="$(date +"%F %T")"
	echo "$DATE ($FONCTION) :: DEBUT"
	echo "$DATE ($FONCTION) :: DEBUT" >> $JOURNAL
}

function finaliseJournalScript
{
	FONCTION=$1
	JOURNAL="${JOURNAL['DOSSIER']}/${JOURNAL['DATE']}"
	DATE="$(date +"%F %T")"
	echo "$DATE ($FONCTION) :: FIN"
	echo "$DATE ($FONCTION) :: FIN" >> $JOURNAL
}

function messageJournalScript
{
	RESULTAT=$1
	FONCTION=$2
	JOURNAL="${JOURNAL['DOSSIER']}/${JOURNAL['DATE']}"
	DATE="$(date +"%F %T")"
	if [[ $RESULTAT -eq 0 ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE['OK']}"
		echo "$DATE ($FONCTION) :: ${MESSAGE['OK']}" >> $JOURNAL
	elif [[ $RESULTAT -eq 1 && $FONCTION != "eix-diff" ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE['KO']}"
		echo "$DATE ($FONCTION) :: ${MESSAGE['KO']}" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 1
	elif [[ $RESULTAT -eq 1 && $FONCTION == "eix-diff" ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE['NA']}"
		echo "$DATE ($FONCTION) :: ${MESSAGE['NA']}" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 0
	else
		echo "$DATE ($FONCTION) :: ${MESSAGE['FATAL']}"
		echo "$DATE ($FONCTION) :: ${MESSAGE['FATAL']}" >> $JOURNAL
		finaliseJournalScript $FONCTION
		exit 2
	fi
}

function rafraichissementEnvironnement
{
	lancer ${ENVU['FONCTION']} "${ENVU['COMMANDE']}" false
	lancer ${SEP['FONCTION']} "${SEP['COMMANDE']}" false
}

#------------
# MISE A JOUR
#------------

case $1 in
-sync)
	lancer ${LS['FONCTION']} "${LS['COMMANDE']}" true
	lancer ${ES['FONCTION']} "${ES['COMMANDE']}" true
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

# Lancement des commandes non forcées
if [[ FORCE -eq 0 ]]
then
	lancer ${EDIF['FONCTION']} "${EDIF['COMMANDE']}" true
fi

# Lancement des commandes de mise à jour présente dans la liste
for i in "${LISTEDEMAJ[@]}"
do
	FONCTION_CONSTRUITE=\${$(echo $i)['FONCTION']}
	COMMANDE_CONSTRUITE=\${$(echo $i)['COMMANDE']}
	FONCTION=$(eval echo ${FONCTION_CONSTRUITE})
	COMMANDE=$(eval echo ${COMMANDE_CONSTRUITE})
	lancer $FONCTION "$COMMANDE" true
done

exit 0
