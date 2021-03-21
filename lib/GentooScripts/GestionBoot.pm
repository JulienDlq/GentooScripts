package GentooScripts::GestionBoot;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(monter_boot demonter_boot);
our @EXPORT_OK = qw($BOOT);

use strict;
use warnings;
use feature 'say';
use Carp;
use Data::Dumper;

use lib './lib';
use GentooScripts::Core;

our $BOOT = '/boot';

# Monter la partition de boot
sub monter_boot {

	# Vérification pour éviter d'avoir des messages d'erreur prévisible
	# de la commande mount
	my $sortie_mount =
	  executer( 'mount | grep ' . $BOOT . ' 2>/dev/null 1>&2' );

	if ( $sortie_mount == 1 ) {

		journaliser( 'La partition ' . $BOOT . ' va être montée.' );
		system 'mount ' . $BOOT;

	} elsif ( $sortie_mount == 0 ) {

		journaliser( 'La partition ' . $BOOT . ' est déjà montée.' );

	} else {

		journaliser( 'Erreur non gérée (Montage "' . $BOOT . '").' );
	}
}

# Démonter la partition de boot
sub demonter_boot {

	# Vérification pour éviter d'avoir des messages d'erreur prévisible
	# de la commande umount
	my $sortie_mount =
	  executer( 'mount | grep ' . $BOOT . ' 2>/dev/null 1>&2' );

	if ( $sortie_mount == 0 ) {

		journaliser( 'La partition ' . $BOOT . ' va être démontée.' );
		system 'umount ' . $BOOT;

	} elsif ( $sortie_mount == 1 ) {

		journaliser( 'La partition ' . $BOOT . ' est déjà démontée.' );

	} else {

		journaliser( 'Erreur non gérée (Démontage "' . $BOOT . '").' );
	}
}

1;

