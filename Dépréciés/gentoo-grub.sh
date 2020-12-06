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
MODULES_PATH=/lib/modules/

# Monter la partition
monterBoot

# Nettoyage des noyaux
echo 'Gestion des noyaux et modules :'
numero_noyau=0
for pattern in $(ls -1t $BOOT | grep vmlinuz | sed 's/^vmlinuz-//')
do
	((numero_noyau++))
	if [[ $numero_noyau -gt $NBMAXKERNEL ]]
	then
		echo '- '$pattern
		find $BOOT -name "*${pattern}" -delete
		find $BOOT -name "*${pattern}.img" -delete
		if [[ -d "${MODULES_PATH}${pattern}" ]]
		then
			rm -rf ${MODULES_PATH}${pattern}
		fi
	else
		echo '+ '$pattern
	fi
done
echo

# Reconfiguration de grub
echo "La configuration de grub va être modifée :"
grub-mkconfig -o ${BOOT}/grub/grub.cfg
echo

# Démonter la partition
demonterBoot

exit 0
