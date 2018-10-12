#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Monter la partition de boot
mount /boot

# Vérification du nombre de noyaux présents
NBNOYAUX=$(cd /boot ; ls -1 *gentoo | sed 's/.*-x86_64-//' | sort | uniq | wc -l)
echo "Il y a actuellement" $NBNOYAUX "noyaux dans /boot"

if [[ $NBNOYAUX -gt 2 ]]
then
	echo "Il serait temps de faire du ménage !"
fi

echo

# Reconfiguration de grub
grub-mkconfig -o /boot/grub/grub.cfg

# Démonter la partition de boot
umount /boot

exit 0
