#!/bin/bash

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-save-config

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

for source in "$sources"
do
        rsync -rRtzuc --progress $source ${sauvegarde}/
done

if [[ -d $sauvegarde ]]
then
	umount $point_de_montage
	rmdir $point_de_montage
fi

exit 0

