#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Configuration du script
. ./gentoo-kernel-config

# Toute la suite va nécessiter des droits d'admin
verificationAdmin

# Variables globales
BOOT=/boot
SRC=/usr/src

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
if [[ $SETMENUCONFIG -eq 1 ]]
then
	MENUCONFIG="--menuconfig"
else
	MENUCONFIG="--no-menuconfig"
fi

case $1 in
	-menuconfig)
		MENUCONFIG="--menuconfig"
		;;
	-no-menuconfig)
		MENUCONFIG="--no-menuconfig"
		;;
	-initramfs-update)
		INITRAMFSUPDATE=1
		;;
	*|"")
		echo "Utilisation : ./$(basename $0) <-menuconfig|-no-menuconfig|-initramfs> [-force]"
		echo "-menuconfig       : lance menuconfig avant la compilation du noyau."
		echo "-no-menuconfig    : ne lance pas menuconfig avant la compilation du noyau."
		echo "-initramfs-update : mettre à jour le fichier initramfs du kernel."
		echo "-force            : force la reconstruction du noyau."
		exit 0
		;;
esac

case $2 in
	-force)
		FORCE=1
		;;
	*|"")
		FORCE=0
		;;
esac

# Fonctions
function noyau_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function noyau_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function noyau_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function noyau_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

function forcer()
{
	if [[ $FORCE -eq 0 ]]
	then
		echo
		exit 0
	else
		echo "Mais la reconstruction est forcée."
		echo
	fi
}

# Monter la partition

# Vérification pour éviter d'avoir des messages d'erreur prévisible
# de la commande mount
mount | grep $BOOT 2>/dev/null 1>&2
result=$?
if [[ $result -eq 1 ]]
then
	echo "La partition "${BOOT}" va être montée."
	mount ${BOOT}
elif [[ $result -eq 0 ]]
then
	echo "La partition "${BOOT}" est déjà montée."
else
	echo "Erreur non gérée (Montage "${BOOT}")."
	exit 1
fi
echo

# Récupération des informations pour la prise de décision
noyau_actuel=$(echo linux-$(uname -r) | sed 's/linux-//')
noyau_a_construire=$(ls -l /usr/src/linux | tr -s ' ' | cut -d' ' -f11 | sed 's/linux-//')
noyau_installe_dernier=$(ls -lrt /boot | tr -s ' ' | cut -d' ' -f9 | grep '^kernel-' | sed 's/kernel-genkernel-x86_64-//' | tail -n1)

echo -n 'Noyau actuel             :' $noyau_actuel
echo
echo -n 'Noyau à construire       :' $noyau_a_construire
echo
echo -n 'Noyau installé (dernier) :' $noyau_installe_dernier
echo
echo

# Démonter la partition

# Vérification pour éviter d'avoir des messages d'erreur prévisible
# de la commande umount
mount | grep $BOOT 2>/dev/null 1>&2
result=$?
if [[ $result -eq 0 ]]
then
	echo "La partition "${BOOT}" va être démontée."
	umount ${BOOT}
elif [[ $result -eq 1 ]]
then
	echo "La partition "${BOOT}" est déjà démontée."
else
	echo "Erreur non gérée (Démontage "${BOOT}")"
	exit 1
fi
echo

# Prise de décision
if [[ $INITRAMFSUPDATE -eq 1 ]]
then
	echo "Le fichier initramfs doit être mis-à-jour."
	echo
else
	if noyau_gt $noyau_a_construire $noyau_installe_dernier
	then
		echo "Le noyau à construire n'est pas encore installé."
		echo
	elif noyau_lt $noyau_a_construire $noyau_installe_dernier
	then
		echo "Le dernier noyau installé est en avance sur le noyau à construire."
		forcer
	else
		echo "Le noyau à construire est déjà installé."
		forcer
	fi
fi


if [[ $INITRAMFSUPDATE -eq 1 ]]
then
	# Dans le cas où il faut mettre à jour le fichier initramfs
	# Il n'y a qu'à lancer la commande de mise-à-jour, rien de plus
	echo 'Lancement de la mise-à-jour du fichier initramfs.'
	dracut --hostonly --force
	echo
else
	# Dans le cas où il faut construire
	# Il faut récupérer la configuration du noyau actuel
	# et la rendre disponible pour le nouveau noyau
	echo 'Récupération de la configuration du noyau actuel'
	cp -v /usr/src/linux-$(uname -r)/.config /usr/src/linux/.config
	echo

	echo 'Lancement de la construction du noyau.'
	genkernel $MENUCONFIG kernel
	echo

	echo 'Lancement de la construction du fichier initramfs.'
	dracut --hostonly --force
	echo
fi

echo "Il ne reste plus qu'à reconfigurer le grub."
echo

exit 0
