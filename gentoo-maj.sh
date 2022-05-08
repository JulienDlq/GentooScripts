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

declare -A ES
ES=(
	['FONCTION']="PORTAGE::SYNC"
	['COMMANDE']="emaint -a sync"
)
declare -A EUC
EUC=(
	  ['FONCTION']="PORTAGE::LIST::UPDATE"
	  ['COMMANDE']="eix -u -c"
)
declare -A EIC
EIC=(
	  ['FONCTION']="PORTAGE::LIST::INSTALLED"
	  ['COMMANDE']="EIX_LIMIT_COMPACT=0 eix -I -c"
)
declare -A ENVU
ENVU=(
	['FONCTION']="SYSTEM::UPDATE::ENV"
	['COMMANDE']="env-update"
)
declare -A SEP
SEP=(
	['FONCTION']="SYSTEM::UPDATE::PROFILE"
	['COMMANDE']="source /etc/profile"
)
declare -A ESU
ESU=(
	['FONCTION']="PORTAGE::EMERGE::SYSTEM ( update )"
	['COMMANDE']="emerge $VERBOSE $QUIET -u --with-bdeps=y @system"
)
declare -A ESUNU
ESUNU=(
	['FONCTION']="PORTAGE::EMERGE::SYSTEM ( update ; new use )"
	['COMMANDE']="emerge $VERBOSE $QUIET -Nu --with-bdeps=y @system"
)
declare -A ESUNUD
ESUNUD=(
	['FONCTION']="PORTAGE::EMERGE::SYSTEM ( update ; new use ; deep )"
	['COMMANDE']="emerge $VERBOSE $QUIET -NuD --with-bdeps=y @system"
)
declare -A EWU
EWU=(
	['FONCTION']="PORTAGE::EMERGE::WORLD ( update )"
	['COMMANDE']="emerge $VERBOSE $QUIET -u --with-bdeps=y @world"
)
declare -A EWUNU
EWUNU=(
	['FONCTION']="PORTAGE::EMERGE::WORLD ( update ; new use )"
	['COMMANDE']="emerge $VERBOSE $QUIET -Nu --with-bdeps=y @world"
)
declare -A EWUNUD
EWUNUD=(
	['FONCTION']="PORTAGE::EMERGE::WORLD ( update ; new use ; deep )"
	['COMMANDE']="emerge $VERBOSE $QUIET -NuD --with-bdeps=y @world"
)
declare -A EPR
EPR=(
	['FONCTION']="PORTAGE::EMERGE::PRESERVEDREBUILD"
	['COMMANDE']="emerge $VERBOSE $QUIET @preserved-rebuild"
)
declare -A EC
EC=(
	['FONCTION']="PORTAGE::EMERGE::REMOVE::OBSOLETES"
	['COMMANDE']="emerge $VERBOSE $QUIET -c"
)
declare -A RR
RR=(
	['FONCTION']="PORTAGE::REBUILD::DEPENDENCIES"
	['COMMANDE']="revdep-rebuild -- $VERBOSE $QUIET"
)
declare -A EU
EU=(
	['FONCTION']="PORTAGE::UPDATE::ETC"
	['COMMANDE']="etc-update $VERBOSE"
)
declare -A ED
ED=(
	['FONCTION']="PORTAGE::CLEAN::DISTFILES"
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
	initialiseJournalScript "$FONCTION"
	eval $COMMANDE
	RESULTAT=$?
	messageJournalScript $RESULTAT "$FONCTION"
	finaliseJournalScript "$FONCTION"
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
  echo
	echo "$FONCTION"
  echo
	echo "$DATE ($FONCTION) :: DEBUT" >> $JOURNAL
}

function finaliseJournalScript
{
	FONCTION=$1
	JOURNAL="${JOURNAL['DOSSIER']}/${JOURNAL['DATE']}"
	DATE="$(date +"%F %T")"
  echo
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
		echo "$DATE ($FONCTION) :: ${MESSAGE['OK']}" >> $JOURNAL
	elif [[ $RESULTAT -eq 1 && $FONCTION == ${EUC['FONCTION']} ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE['OK']}" >> $JOURNAL
	  finaliseJournalScript "$FONCTION"
	elif [[ $RESULTAT -eq 1 && $FONCTION != ${EUC['FONCTION']} ]]
	then
    echo
		echo "$FONCTION :: ${MESSAGE['KO']}"
    echo
		echo "$DATE ($FONCTION) :: ${MESSAGE['KO']}" >> $JOURNAL
		finaliseJournalScript "$FONCTION"
		exit 1
	else
    echo
		echo "$FONCTION :: ${MESSAGE['FATAL']}"
    echo
		echo "$DATE ($FONCTION) :: ${MESSAGE['FATAL']}" >> $JOURNAL
		finaliseJournalScript "$FONCTION"
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
  # Toute la suite va nécessiter des droits d'admin
  verificationAdmin
#	lancer ${LS['FONCTION']} "${LS['COMMANDE']}" true
	lancer ${ES['FONCTION']} "${ES['COMMANDE']}" true
;;
-synconly)
  # Toute la suite va nécessiter des droits d'admin
  verificationAdmin
#	lancer ${LS['FONCTION']} "${LS['COMMANDE']}" true
	lancer ${ES['FONCTION']} "${ES['COMMANDE']}" true
	exit 0
;;
-nosync)
  # Toute la suite va nécessiter des droits d'admin
  verificationAdmin
;;
-listupdate)
  lancer ${EUC['FONCTION']} "${EUC['COMMANDE']}" false
  exit 0
;;
-listinstalled)
	lancer ${EIC['FONCTION']} "${EIC['COMMANDE']}" false
	exit 0
;;
*|"")
	echo "Utilisation : ./$(basename $0) <-sync|-nosync>"
	echo "-sync          : synchronise l'arbre portage et la recherche eix avant la mise à jour."
	echo "-synconly      : synchronise l'arbre portage et la recherche eix sans mettre à jour."
	echo "-nosync        : lance la mise à jour sans synchroniser l'arbre portage et la recherche eix."
	echo "-listupdate    : lister les mises à jour disponibles."
	echo "-listinstalled : lister les paquets installés."
	exit 0
;;
esac

# Lancement des commandes de mise à jour présente dans la liste
for i in "${LISTEDEMAJ[@]}"
do
	FONCTION_CONSTRUITE=\${$(echo $i)['FONCTION']}
	COMMANDE_CONSTRUITE=\${$(echo $i)['COMMANDE']}
	FONCTION=$(eval echo ${FONCTION_CONSTRUITE})
	COMMANDE=$(eval echo ${COMMANDE_CONSTRUITE})
	lancer "$FONCTION" "$COMMANDE" true
done

exit 0
