#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

# Configuration du script
NBMAXKERNEL=2

# Variables globales
BOOT=/boot
SRC=/usr/src

# Réaliser les opérations suivantes aussi bien dans ${BOOT} que dans ${SRC}
for Chemin in ${BOOT} ${SRC}
do
	echo "Chemin en cours : "${Chemin}"."
	echo

	# Monter la partition
	if [[ $Chemin == ${BOOT} ]]
	then
		# Vérification pour éviter d'avoir des messages d'erreur prévisible
		# de la commande mount
		mount | grep $Chemin 2>/dev/null 1>&2
		result=$?
		if [[ $result -eq 1 ]]
		then
			echo "La partition "${Chemin}" va être montée."
			mount ${Chemin}
		elif [[ $result -eq 0 ]]
		then
			echo "La partition "${Chemin}" est déjà montée."
		else
			echo "Erreur non gérée (Montage "${Chemin}")"
			exit 1
		fi
		echo
	elif [[ $Chemin == ${SRC} ]]
	then
		# Pas d'opération spécifique pour ce $Chemin
		test
	else
		# On ne devrait jamais passer par ici, mais au moins on s'évite quelques problèmes
		# le jour où on modifie la liste des chemins possibles sans avoir aussi modifié
		# tout le bloc if-elif-else-fi
		echo "Le chemin "${Chemin}" est inconnu !"
		exit 1
	fi

	# Récupération du chemin
	if [[ $Chemin == ${BOOT} ]]
	then
		KernelVersions=($(ls -1 ${BOOT}/*gentoo | sed 's/.*-x86_64-//' | sort -V | uniq))
	elif [[ $Chemin == ${SRC} ]]
	then
		KernelVersions=($(ls -1d ${SRC}/*gentoo | sed 's/.*linux-//' | sort -V | uniq))
	else
		# On ne devrait jamais passer par ici, mais au moins on s'évite quelques problèmes
		# le jour où on modifie la liste des chemins possibles sans avoir aussi modifié
		# tout le bloc if-elif-else-fi
		echo "Le chemin "${Chemin}" est inconnu !"
		exit 1
	fi

	# Affichage du nombre de noyaux présents dans ${Chemin}
	echo -n "Il y a "${#KernelVersions[*]}" Noyau(x) dans "${Chemin}" => "
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

	# Récupération du prefixe
	if [[ $Chemin == ${BOOT} ]]
	then
		Prefixe="*-x86_64-"
	elif [[ $Chemin == ${SRC} ]]
	then
		Prefixe="linux-"
	else
		# On ne devrait jamais passer par ici, mais au moins on s'évite quelques problèmes
		# le jour où on modifie la liste des chemins possibles sans avoir aussi modifié
		# tout le bloc if-elif-else-fi
		echo "Le chemin "${Chemin}" est inconnu !"
		exit 1
	fi

	# Suppression des versions obsolètes dans ${Chemin}
	if [[ ${#KernelVersions[*]} -eq 0 ]]
	then
		echo "Pas de noyau à supprimer."
	else
		echo "Le(s) noyau(x) suivant(s) est(sont) supprimé(s) :"
	fi
	for Kernel in ${KernelVersions[*]}
	do
		echo "- "${Kernel}
		rm -rf ${Chemin}/${Prefixe}${Kernel}
	done
	echo

	# Reconfiguration de grub
	if [[ $Chemin == ${BOOT} ]]
	then
		echo "La configuration de grub va être modifée."
		grub-mkconfig -o ${BOOT}/grub/grub.cfg
		echo
	elif [[ $Chemin == ${SRC} ]]
	then
		# Pas d'opération spécifique pour ce $Chemin
		test
	else
		# On ne devrait jamais passer par ici, mais au moins on s'évite quelques problèmes
		# le jour où on modifie la liste des chemins possibles sans avoir aussi modifié
		# tout le bloc if-elif-else-fi
		echo "Le chemin "${Chemin}" est inconnu !"
		exit 1
	fi

	# Démonter la partition
	if [[ $Chemin == ${BOOT} ]]
	then
		# Vérification pour éviter d'avoir des messages d'erreur prévisible
		# de la commande umount
		mount | grep $Chemin 2>/dev/null 1>&2
		result=$?
		if [[ $result -eq 0 ]]
		then
			echo "La partition "${Chemin}" va être démontée."
			umount ${Chemin}
		elif [[ $result -eq 1 ]]
		then
			echo "La partition "${Chemin}" est déjà démontée."
		else
			echo "Erreur non gérée (Démontage "${Chemin}")"
			exit 1
		fi
		echo
	elif [[ $Chemin == ${SRC} ]]
	then
		# Pas d'opération spécifique pour ce $Chemin
		test
	else
		# On ne devrait jamais passer par ici, mais au moins on s'évite quelques problèmes
		# le jour où on modifie la liste des chemins possibles sans avoir aussi modifié
		# tout le bloc if-elif-else-fi
		echo "Le chemin "${Chemin}" est inconnu !"
		exit 1
	fi

done

exit 0
