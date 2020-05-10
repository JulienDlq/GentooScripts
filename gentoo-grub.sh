#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-grub-config

# Toute la suite va nécessiter des droits d'admin
verificationAdmin

# Valeur par défaut pour le nombre maximum de noyau à conserver
if [[ -z "$NBMAXKERNEL" ]]
then
	echo "NBMAXKERNEL non configuré, valeur par défaut 2."
	NBMAXKERNEL=2
fi

# Variables globales
BOOT=/boot
SRC=/usr/src

# Penser à installer app-admin/eclean-kernel
# Nettoyer en mode destructif (on ne veut garder que les NBMAXKERNEL noyaux même s'ils sont référencés dans GRUB)
echo "Nettoyage des Noyaux :"
eclean-kernel -d -n $NBMAXKERNEL
echo

# Monter la partition
# Vérification pour éviter d'avoir des messages d'erreur prévisible
# de la commande mount
mount | grep $BOOT 2>/dev/null 1>&2
result=$?
if [[ $result -eq 1 ]]
then
	mount ${BOOT}
elif [[ $result -eq 0 ]]
then
	echo "La partition "${BOOT}" est déjà montée."
	echo
else
	echo "Erreur non gérée (Montage "${BOOT}")"
	echo
	exit 1
fi

# Reconfiguration de grub
echo "La configuration de grub va être modifée :"
grub-mkconfig -o ${BOOT}/grub/grub.cfg
echo

# Démonter la partition
# Vérification pour éviter d'avoir des messages d'erreur prévisible
# de la commande umount
mount | grep $BOOT 2>/dev/null 1>&2
result=$?
if [[ $result -eq 0 ]]
then
	umount ${BOOT}
elif [[ $result -eq 1 ]]
then
	echo "La partition "${BOOT}" est déjà démontée."
	echo
else
	echo "Erreur non gérée (Démontage "${BOOT}")"
	echo
	exit 1
fi

exit 0
