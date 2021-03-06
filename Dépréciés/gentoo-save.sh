#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Chargement de la configuration du script
. ./gentoo-save-config

# Toute la suite va nécessiter des droits d'admin
verificationAdmin

# Si la sauvegarde est samba et que la configuration correspondante est paramétrée, alors on configure le partage
if [[ "$type" == "samba" && "$serveur" != "" && "$dossier" != "" ]]
then
	# Partage qui sera ainsi utilisé
	partage="//${serveur}/${dossier}"
# Et si la sauvegarde est locale, alors pas besoin de partage
elif [[ "$type" == "local" ]]
then
	partage=""
# Et si la sauvegarde est samba et que la configuration correspondante n'est pas paramétrée, alors on s'arrête
elif [[ "$type" == "samba" && "$serveur" == "" && "$dossier" == "" ]]
then
	echo "Les variables serveur et dossier ne sont pas paramétrées pour ce type ($type)"
	exit 1
# Dans tous les autres cas on s'arrête…
else
	echo "Ce type n'est pas encore géré ! (type = $type)"
	exit 1
fi

# Si la configuration correspondante est paramétrée, alors on configure la destination de la sauvegarde
if [[ "$destination_racine" != "" && "$hote" != "" ]]
then
	sauvegarde="${destination_racine}/${hote}"
fi

# Nom de la liste de sauvegarde
liste="sauvegarde.list"

# Vérifier si les sources sont paramétrées
if [[ "$sources" == "" ]]
then
	echo "Sources vide ! Configurer la variable \"sources\" et recommencer"
	exit 1
fi

# Chaque source doit exister sur le système
source_inexistante_declanchee=0
sources_inexistantes=""
for source_courante in $sources
do
	if [[ ! -e $source_courante ]]
	then
		source_inexistante_declanchee=1
		sources_inexistantes="$sources_inexistantes $source_courante"
	fi
done

# Dans le cas où une ou plusieurs sources n'existent pas prévenir l'utilisateur
if (( $source_inexistante_declanchee ))
then
	if [[ $( echo $sources_inexistantes | wc -w ) == 1 ]]
	then
		echo "La source$sources_inexistantes n'existe pas sur le système de fichier"
	else
		echo "Les sources$sources_inexistantes n'existent pas sur le système de fichier"
	fi
	exit 1
fi

# Si la sauvegarde n'est pas locale, monter le dossier de sauvegarde si ce n'est déjà fait
if [[ "$type" != "local" && ! -d $sauvegarde ]]
then
	mkdir -p $destination_racine
	mount -t cifs -o guest $partage $destination_racine
	if [[ $? -ne 0 ]]
	then
		echo "Erreur non gérée"
		exit 1
	fi
	mkdir -p $sauvegarde
# Si la sauvegarde est locale, créer le dossier de sauvegarde si ce n'est déjà fait
elif [[ "$type" == "local" && ! -d $sauvegarde ]]
then
	mkdir -p $sauvegarde
else
	echo "Le dossier de sauvegarde est déjà présent (sauvegarde = $sauvegarde)"
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

# Si la sauvegarde n'est pas locale, démonter le dossier de sauvegarde si ce n'est déjà fait
if [[ "$type" != "local" && -d $sauvegarde ]]
then
	umount $destination_racine
	rmdir $destination_racine
fi

exit 0

