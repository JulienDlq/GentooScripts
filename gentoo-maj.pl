#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Basename;
use File::Path qw(remove_tree);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use Sort::Versions;

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

require './gentoo-maj-config.pl';
our $CONFIG;

###
# Toute la suite va nécessiter des droits d'admin

verification_admin();

###
# Gestion des arguments

my $variables = gestion_arguments(
	{
		# Usage général
		'usage_general' => 'Usage : '
		  . $NOM_DU_SCRIPT
		  . ' [--sync]'
		  . ' [--synconly]'
		  . ' [--nosync]'
		  . ' [--listupdate]'
		  . ' [--listinstalled]',
		'usage_ordre' => [ 'sync', 'synconly', 'nosync', 'listupdate', 'listinstalled', ],

		# Arguments et usage spécifique
		'arguments' => {
			'menuconfig' => {
				'usage' => '-m, --menuconfig       :'
				  . ' lancer menuconfig avant la compilation du noyau (oui ou non).',
				'type'    => 'm=s',
				'conf'    => $CONFIG->{'menuconfig'},
				'defaut'  => 0,
				'booleen' => 1,
			},
			'force' => {
				'usage' => '-f, --force            :'
				  . ' forcer la reconstruction du noyau.',
				'type'   => 'f',
				'defaut' => 0,
			},
			'initramfs-update' => {
				'usage' => '-i, --initramfs-update :'
				  . ' mettre à jour le fichier initramfs du kernel uniquement.',
				'type'      => 'i',
				'defaut'    => 0,
				'desactive' => 1,
			},
		},
	},
);

###
# Lancement du programme principal

my $message = {
	'ok'    => 'Tout s\'est bien passé. ;-)',
	'ko'    => 'Il y a eu un soucis… :-S',
	'na'    => 'Il y n\'y a pas de mise à jour à faire… :-O',
	'fatal' => 'Il y a eu une erreur fatale non gérée… x.x',
};

my $journal = {
    'dossier' => '/var/log/gentooscripts',
    'date'    => `date +%F-%H%M%S` . '.log',
};

journaliser('Il ne reste plus qu\'à mettre à jour.');

exit 0;

