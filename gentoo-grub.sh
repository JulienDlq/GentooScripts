#!/bin/bash

SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
cd $SCRIPTPATH

# Initialisation du script
. ./init

mount /boot
grub-mkconfig -o /boot/grub/grub.cfg
umount /boot

exit 0
