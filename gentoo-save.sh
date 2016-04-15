#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-save-config

# Récupération de la date
date=$(date +%F-%H%M)

if [[ "$sources" == "" ]]
then
	echo "Sources vide ! Configurer la variable \"sources\" et recommencer"
	exit 1
fi

if [[ ! -d $sauvegarde ]]
then
	mkdir -p $point_de_montage
	mount -t cifs -o guest $partage $point_de_montage
	if [[ $? -ne 0 ]]
	then
		echo "Erreur non gérée"
		exit 1
	fi
fi

# Vérifier s'il existe une archive sur laquelle se baser
archive="$(ls -1t ${sauvegarde} | head -n1 | grep .tar.gz)"
if [[ "$archive" != "" && "$archive" != "${date}.tar.gz" ]]
then
	cp ${sauvegarde}/$archive ${sauvegarde}/${date}.tar.gz
fi

# Mise à jour de l'archive (ou création s'il n'existait pas d'archive sur laquelle se baser
tar uPvf ${sauvegarde}/${date}.tar.gz $sources

if [[ -d $sauvegarde ]]
then
	umount $point_de_montage
	rmdir $point_de_montage
fi

exit 0

