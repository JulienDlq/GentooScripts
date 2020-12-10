#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Basename;
use File::Path qw(remove_tree);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

my $NOM_DU_SCRIPT;
my $CHEMIN_DU_SCRIPT;
my $LIB;

BEGIN {
    $NOM_DU_SCRIPT    = basename($0);
    $CHEMIN_DU_SCRIPT = dirname($0);
    chdir $CHEMIN_DU_SCRIPT;
    $LIB = $CHEMIN_DU_SCRIPT . '/lib';
}

###
# Initialisation du script

use lib $LIB;
use GentooScripts::Core;
use GentooScripts::GestionBoot;
use GentooScripts::GestionBoot qw($BOOT);
our $BOOT;

###
# Chargement de la configuration du script

require './gentoo-grub-config.pl';
our $CONFIG;


###
# Toute la suite va nécessiter des droits d'admin

verification_admin();


###
# Traitement de la configuration du script

if ( not exists( $CONFIG->{'nbmaxkernel'} ) ) {
    journaliser('La valeur "nbmaxkernel" est non configuré, valeur par défaut mise à "2".');
    $CONFIG->{'nbmaxkernel'} = 2;
}


###
# Créations de variables globales

my $MODULES_PATH = '/lib/modules/';
my $SRC_PATH = '/usr/src/';


###
# Monter la partition

monter_boot();


###
# Nettoyage des noyaux

journaliser('Gestion des noyaux, des modules et des sources :');

# Servira à compter les noyaux
my $numero_noyau = 0;

# Lister les noyaux présents dans $BOOT
my $command = 'ls -1t ' . $BOOT;
my @results = qx($command);
chomp @results;
my @liste_noyaux = map { /^vmlinuz-(.*)/ } grep { /vmlinuz/ } @results;

# Parcours et traîtement de la liste des noyaux
foreach my $noyau (@liste_noyaux) {

    # Numéroter le noyau en cours de traîtement
    $numero_noyau++;

    # Prise de décision si le noyau en cours de traîtement est de trop ou non
    if ( $numero_noyau > $CONFIG->{'nbmaxkernel'} ) {

        say '- '.$noyau;

        # Suppression du noyau en cours de traîtement de $BOOT
        my $command = 'ls -1t ' . $BOOT . '/*' . $noyau . '*';
        my @results = qx($command);
        chomp @results;
        unlink @results;

        # Suppression des modules du noyau en cours de traîtement
        if ( -e -d $MODULES_PATH . $noyau ) {
            remove_tree(
                $MODULES_PATH . $noyau,
                {
                    safe    => 1,
                }
            );
        }

        # Suppression des sources du noyau en cours de traîtement
        my $src_noyau = $noyau;
        $src_noyau =~ s/^/linux-/;
        $src_noyau =~ s/-x86_64//;
        if ( -e -d $SRC_PATH . $src_noyau ) {
            remove_tree(
                $SRC_PATH . $src_noyau,
                {
                    safe    => 1,
                }
            );
        }
    } else {

        say '+ ' . $noyau;
    }
}

###
# Reconfigurer le GRUB

journaliser('La configuration de grub va être modifée :');
executer( 'grub-mkconfig -o ' . $BOOT . '/grub/grub.cfg' );


###
# Démonter la partition

demonter_boot();


###
#
exit 0;

