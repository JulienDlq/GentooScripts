#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Configuration du script
NBMAXKERNEL=2

# Monter la partition de boot
mount /boot

# Affichage du nombre de noyaux présents
KernelVersions=($(ls -1 /boot/*gentoo | sed 's/.*-x86_64-//' | sort -V | uniq))
echo -n "Il y a "${#KernelVersions[*]}" Noyau(x) dans /boot => "
if [[ ${#KernelVersions[*]} -gt $NBMAXKERNEL ]]
then
	echo "Il serait temps de faire du ménage !"
elif [[ ${#KernelVersions[*]} -eq $NBMAXKERNEL ]]
then
	echo "Ok."
else
	echo "Il y a moins de noyau(x) que le max prévu ("$NBMAXKERNEL")."
	NBMAXKERNEL=${#KernelVersions[*]}
fi
echo

# Affichage de ces noyaux
echo "Liste de(s) noyau(x) :"
for Kernel in ${KernelVersions[*]}
do
    echo "- "${Kernel}
done
echo

# Affichage des noyaux à conserver
echo "Il faudrait conserver le(s) noyau(x) suivant(s) :"
for (( Kernel=1 ; Kernel <= $NBMAXKERNEL ; Kernel++ ))
do
	echo "- "${KernelVersions[-1]}
	unset KernelVersions[-1]
done
echo

# Suppression des versions obsolètes
if [[ ${#KernelVersions[*]} -eq 0 ]]
then
	echo "Pas de noyau à supprimer."
else
	echo "Le(s) noyau(x) suivant(s) sont supprimés :"
fi
for Kernel in ${KernelVersions[*]}
do
    echo "- "${Kernel}
	rm /boot/*-x86_64-${Kernel}
done
echo

# Reconfiguration de grub
grub-mkconfig -o /boot/grub/grub.cfg

# Démonter la partition de boot
umount /boot

exit 0
