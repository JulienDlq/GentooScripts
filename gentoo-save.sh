#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-save-config

# Nom de la liste de sauvegarde
liste="sauvegarde.list"

# Vérifier si les sources existent
if [[ "$sources" == "" ]]
then
	echo "Sources vide ! Configurer la variable \"sources\" et recommencer"
	exit 1
fi

# Monter le dossier de sauvegarde si ce n'est déjà fait
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

# Récupérer l'ID de l'archive courante
id_archive="$((ls -1t ${sauvegarde}/sauvegarde.*.tar.gz 2>/dev/null ) | head -n1 | sed 's/.*sauvegarde\.\(.*\)\.tar.gz/\1/g')"

# Si l'ID de l'archive courante n'est pas un nombre, alors on l'initialise à zéro
# Sinon on l'incrémente
regexp='^[0-9]+$'
if ! [[ $id_archive =~ $regexp ]]
then
	id_archive=0
	echo "Archive complète a créer (cela peut prendre du temps...), id=${id_archive}."
else
	id_archive="$(echo $(( $id_archive + 1 )))"
	echo "Archive incrémentale a créer, id=${id_archive}."
fi

# Création de la nouvelle archive incrémentale
tar -g ${sauvegarde}/${liste} -zcPf ${sauvegarde}/sauvegarde.${id_archive}.tar.gz $sources 2>/dev/null

# Signaler la fin de l'opération
resultat=$?
if [[ $resultat -eq 0 ]]
then
	if [[ $id_archive -eq 0 ]]
	then
		echo "Archive complète créée, id=${id_archive}."
	else
		echo "Archive incrémentale créée, id=${id_archive}."
	fi
elif [[ $resultat -eq 1 ]]
then
	if [[ $id_archive -eq 0 ]]
	then
		echo "Archive complète créée (mais des fichiers ont changé pendant l'archivage), id=${id_archive}."
	else
		echo "Archive incrémentale créée (mais des fichiers ont changé pendant l'archivage), id=${id_archive}."
	fi
else
	echo "La sauvegarde a échoué... :("
	exit 1
fi

# Démonter le dossier de sauvegarde si ce n'est déjà fait
if [[ -d $sauvegarde ]]
then
	umount $point_de_montage
	rmdir $point_de_montage
fi

exit 0

