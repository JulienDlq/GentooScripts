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
	export PASSPHRASE=$passphrase
	duplicity $target file://$sauvegarde/$(basename $target | sed 's/\.//g' )/
done

exit 0

