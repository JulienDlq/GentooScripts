#!/usr/bin/env zsh

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


typeset -A MESSAGE=(
	'OK'
	"Tout s'est bien passé. ;-)"
	'KO'
	"Il y a eu un soucis... :-S"
	'NA'
	"Il y n'y a pas de mise à jour à faire... :-O"
	'FATAL'
	"Il y a eu une erreur fatale non gérée... x.x"
)

typeset -A JOURNAL=(
	'DOSSIER'
	"/var/log/gentooscripts"
	'DATE'
	"$(date +%F-%H%M%S).log"
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

typeset -a LISTEDEMAJ=(
	ESUNUD
	EPR
	EWUNUD
	EPR
	EC
	EPR
	RR
	EU
	ED
)

typeset -A ES=(
	'FONCTION'
	"PORTAGE::SYNC"
	'COMMANDE'
	"emaint -a sync"
)
typeset -A EUC=(
	  'FONCTION'
	  "PORTAGE::LIST::UPDATE"
	  'COMMANDE'
	  "eix -u -c"
)
typeset -A EIC=(
	  'FONCTION'
	  "PORTAGE::LIST::INSTALLED"
	  'COMMANDE'
	  "EIX_LIMIT_COMPACT=0 eix -I -c"
)
typeset -A ENVU=(
	'FONCTION'
	"SYSTEM::UPDATE::ENV"
	'COMMANDE'
	"env-update"
)
typeset -A SEP=(
	'FONCTION'
	"SYSTEM::UPDATE::PROFILE"
	'COMMANDE'
	"source /etc/profile"
)
typeset -A ESUNUD=(
	'FONCTION'
	"PORTAGE::EMERGE::SYSTEM ( update ; new use ; deep )"
	'COMMANDE'
	"emerge $VERBOSE $QUIET -NuD --with-bdeps=y @system"
)
typeset -A EWUNUD=(
	'FONCTION'
	"PORTAGE::EMERGE::WORLD ( update ; new use ; deep )"
	'COMMANDE'
	"emerge $VERBOSE $QUIET -NuD --with-bdeps=y @world"
)
typeset -A EPR=(
	'FONCTION'
	"PORTAGE::EMERGE::PRESERVEDREBUILD"
	'COMMANDE'
	"emerge $VERBOSE $QUIET @preserved-rebuild"
)
typeset -A EC=(
	'FONCTION'
	"PORTAGE::EMERGE::REMOVE::OBSOLETES"
	'COMMANDE'
	"emerge $VERBOSE $QUIET -c"
)
typeset -A RR=(
	'FONCTION'
	"PORTAGE::REBUILD::DEPENDENCIES"
	'COMMANDE'
	"revdep-rebuild -- $VERBOSE $QUIET"
)
typeset -A EU=(
	'FONCTION'
	"PORTAGE::UPDATE::ETC"
	'COMMANDE'
	"etc-update $VERBOSE"
)
typeset -A ED=(
	'FONCTION'
	"PORTAGE::CLEAN::DISTFILES"
	'COMMANDE'
	"eclean -v distfiles"
)

mkdir -p ${JOURNAL[DOSSIER]}

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
	local JOURNAL="${JOURNAL[DOSSIER]}/${JOURNAL[DATE]}"
	DATE="$(date +"%F %T")"
	echo
	echo "$FONCTION"
	echo
	echo "$DATE ($FONCTION) :: DEBUT" >> $JOURNAL
}

function finaliseJournalScript
{
	FONCTION=$1
	local JOURNAL="${JOURNAL[DOSSIER]}/${JOURNAL[DATE]}"
	DATE="$(date +"%F %T")"
	echo
	echo "$DATE ($FONCTION) :: FIN" >> $JOURNAL
}

function messageJournalScript
{
	RESULTAT=$1
	FONCTION=$2
	local JOURNAL="${JOURNAL[DOSSIER]}/${JOURNAL[DATE]}"
	DATE="$(date +"%F %T")"
	if [[ $RESULTAT -eq 0 ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE[OK]}" >> $JOURNAL
	elif [[ $RESULTAT -eq 1 && $FONCTION == ${EUC[FONCTION]} ]]
	then
		echo "$DATE ($FONCTION) :: ${MESSAGE[OK]}" >> $JOURNAL
		finaliseJournalScript "$FONCTION"
	elif [[ $RESULTAT -eq 1 && $FONCTION != ${EUC[FONCTION]} ]]
	then
		echo
		echo "$FONCTION :: ${MESSAGE[KO]}"
		echo
		echo "$DATE ($FONCTION) :: ${MESSAGE[KO]}" >> $JOURNAL
		finaliseJournalScript "$FONCTION"
		exit 1
	else
		echo
		echo "$FONCTION :: ${MESSAGE[FATAL]}"
		echo
		echo "$DATE ($FONCTION) :: ${MESSAGE[FATAL]}" >> $JOURNAL
		finaliseJournalScript "$FONCTION"
		exit 2
	fi
}

function rafraichissementEnvironnement
{
	lancer ${ENVU[FONCTION]} "${ENVU[COMMANDE]}" false
	lancer ${SEP[FONCTION]} "${SEP[COMMANDE]}" false
}

#------------
# MISE A JOUR
#------------

case $1 in
-sync)
	# Toute la suite va nécessiter des droits d'admin
	verificationAdmin
	lancer ${ES[FONCTION]} "${ES[COMMANDE]}" true
;;
-synconly)
	# Toute la suite va nécessiter des droits d'admin
	verificationAdmin
	lancer ${ES[FONCTION]} "${ES[COMMANDE]}" true
	exit 0
;;
-nosync)
	# Toute la suite va nécessiter des droits d'admin
	verificationAdmin
;;
-listupdate)
	lancer ${EUC[FONCTION]} "${EUC[COMMANDE]}" false
	exit 0
;;
-listinstalled)
	lancer ${EIC[FONCTION]} "${EIC[COMMANDE]}" false
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
	FONCTION_CONSTRUITE=\${$(echo $i)[FONCTION]}
	COMMANDE_CONSTRUITE=\${$(echo $i)[COMMANDE]}
	FONCTION=$(eval echo ${FONCTION_CONSTRUITE})
	COMMANDE=$(eval echo ${COMMANDE_CONSTRUITE})
	lancer "$FONCTION" "$COMMANDE" true
done

exit 0
