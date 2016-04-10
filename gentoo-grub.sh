#!/bin/bash

. ./init

mount /boot
grub2-mkconfig -o /boot/grub/grub.cfg
umount /boot

exit 0
