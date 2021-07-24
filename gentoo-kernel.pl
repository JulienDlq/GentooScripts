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

require './gentoo-kernel-config.pl';
our $CONFIG;

###
# Toute la suite va nécessiter des droits d'admin

verification_admin();

###
# Gestion des arguments

my $variables = gestion_arguments(
	{
		# Usage général
		'usage_general' => 'Usage : ' . $NOM_DU_SCRIPT . ' <--menuconfig=<oui|non>' . ' [--force]' . ' | --initramfs-update>',
		'usage_ordre'   => [ 'menuconfig', 'force', 'initramfs-update', ],

		# Arguments et usage spécifique
		'arguments' => {
			'menuconfig' => {
				'alias'   => 'm',
				'usage'   => 'lancer menuconfig avant la compilation du noyau (oui ou non).',
				'conf'    => $CONFIG->{'menuconfig'},
				'defaut'  => 0,
				'booleen' => 1,
			},
			'force' => {
				'alias'  => 'f',
				'usage'  => 'forcer la reconstruction du noyau.',
				'defaut' => 0,
			},
			'initramfs-update' => {
				'alias'  => 'i',
				'usage'  => 'mettre à jour le fichier initramfs du kernel uniquement.',
				'defaut' => 0,
			},
		},
	},
);

###
# Lancement du programme principal

my $SRC = '/usr/src';

sub lancer_dracut {

	my $parametres             = shift;
	my $construction_initramfs = $parametres->{'construction_initramfs'};
	my $noyau_a_construire     = $parametres->{'noyau_a_construire'};

	if ($construction_initramfs) {

		if ( -f $BOOT . '/initramfs-' . $noyau_a_construire . '-x86_64.img' ) {

			journaliser('Sauvegarde du fichier initramfs précédent.');

			executer( 'mv '
				  . $BOOT
				  . '/initramfs-'
				  . $noyau_a_construire
				  . '-x86_64.img '
				  . $BOOT
				  . '/initramfs-'
				  . $noyau_a_construire
				  . '-x86_64.old.img' );
		}

		journaliser('Lancement de la construction du fichier initramfs.');
	} else {

		journaliser('Lancement de la mise-à-jour du fichier initramfs.');
	}
	executer(
		'dracut --hostonly --force --kver ' . $noyau_a_construire . '-x86_64' );
}

sub forcer {

	my $forcer = shift;

	if ($forcer) {

		journaliser('Mais la reconsruction est forcée.');

	} else {

		exit 0;
	}
}

sub noyau_gt {

	my $parametres             = shift;
	my $noyau_a_construire     = $parametres->{'noyau_a_construire'};
	my $noyau_installe_dernier = $parametres->{'noyau_installe_dernier'};

	return ( versioncmp( $noyau_a_construire, $noyau_installe_dernier ) == 1 );
}

sub noyau_lt {

	my $parametres             = shift;
	my $noyau_a_construire     = $parametres->{'noyau_a_construire'};
	my $noyau_installe_dernier = $parametres->{'noyau_installe_dernier'};

	return ( versioncmp( $noyau_a_construire, $noyau_installe_dernier ) == -1 );
}

my $MENUCONFIG = ( $variables->{'menuconfig'} ? '--' : '--no-' ) . 'menuconfig';

# Monter la partition
monter_boot();

# Récupération des informations pour la prise de décision
my $noyau_actuel = `uname -r | sed 's/-x86_64//'`;
chomp($noyau_actuel);
my $noyau_a_construire =
  `eselect kernel show | tail -n1 | tr -s ' ' | sed 's/.*linux-//'`;
chomp($noyau_a_construire);
my $noyau_installe_dernier =
`ls -1rt $BOOT | grep '^vmlinuz-' | sed 's/vmlinuz-//' | sed 's/-x86_64//' | tail -n1`;
chomp($noyau_installe_dernier);

# Démonter la partition
demonter_boot();

# Prise de décision
if ( $variables->{'initramfs-update'} ) {

	journaliser('Le fichier initramfs doit être mis-à-jour.');

} else {

	if ( noyau_gt( {
		'noyau_a_construire'     => $noyau_a_construire,
		'noyau_installe_dernier' => $noyau_installe_dernier,
	} ) ) {
		journaliser('Le noyau à construire n\'est pas encore installé.');
	} elsif ( noyau_lt( {
		'noyau_a_construire'     => $noyau_a_construire,
		'noyau_installe_dernier' => $noyau_installe_dernier,
	} ) ) {
		journaliser(
'Le dernier noyau installé est en avance sur le noyau à construire.'
		);
		forcer( $variables->{'force'} );

	} else {

		journaliser('Le noyau à construire est déjà installé.');
		forcer( $variables->{'force'} );
	}
}

# Execution
if ( $variables->{'initramfs-update'} ) {

	# Monter la partition
	monter_boot();

	# Mise à jour du fichier initramfs
	lancer_dracut( {
		'construction_initramfs' => 0,
		'noyau_a_construire'     => $noyau_a_construire,
	} );

	# Démonter la partition
	demonter_boot();
} else {

	# Dans le cas où il faut construire
	# Il faut récupérer la configuration du noyau actuel
	# et la rendre disponible pour le nouveau noyau
	journaliser('Récupération de la configuration du noyau actuel');
	executer( 'cp -v /usr/src/linux-'
		  . $noyau_actuel
		  . '/.config /usr/src/linux/.config' );

	journaliser('Lancement de la construction du noyau.');
	executer( 'genkernel ' . $MENUCONFIG . ' kernel' );

	# Monter la partition
	monter_boot();

	# Mise à jour du fichier initramfs
	lancer_dracut( {
		'construction_initramfs' => 1,
		'noyau_a_construire'     => $noyau_a_construire,
	} );

	# Démonter la partition
	demonter_boot();
}

journaliser('Il ne reste plus qu\'à reconfigurer le grub.');

exit 0;

