#!/bin/bash

. ./init

# Serveur accueillant la sauvegarde (préciser le nom d'hôte du serveur ou son adresse IP)
serveur="SERVERNAME"
# Dossier sur le serveur accueillant la sauvegarde (par défaut le nom d'hôte ou l'adresse IP du serveur)
dossier="$serveur"
# Partage qui sera ainsi utilisé
partage="//${serveur}/${dossier}"
# Point de montage du partage
point_de_montage="/tmp/savedest"
# Destination de la sauvegarde (préciser le nom d'hôte de la Gentoo pour plus de facilité)
sauvegarde="${point_de_montage}/GENTOOHOSTNAME"

# Sources contient une liste de fichiers et/ou de dossiers à sauvegarder
# Dossier de configurations des logiciels
# Fichier .config contenant la configuration du noyau courrant
# Fichier world contenant la liste des packets explicitement installés par l'utilisateur
# À compléter au besoin...
sources="\
/etc/ \
/usr/src/linux/.config \
/var/lib/portage/world \
"

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

