#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

## Initialisation du script
#. ./init

# Chargement de la configuration du script
. ./gentoo-save-duplicity-config

# Vérifier si les sources existent
if [[ "$sources" == "" ]]
then
	echo "Sources vide ! Configurer la variable \"sources\" et recommencer"
	exit 1
fi

# Création de la nouvelle archive incrémentale
for target in $sources
do
	echo "Sauvegarde de la cible : $target"
	export PASSPHRASE=$passphrase
	duplicity $target ${protocole}://${sauvegarde}/$(basename $target | sed 's/\.//g' )/
	unset PASSPHRASE
done

exit 0

