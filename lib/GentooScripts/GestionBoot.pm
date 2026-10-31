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

	# Vérification de l'état du montage pour éviter des erreurs
	my $sortie_mount =
	  executer( 'findmnt ' . $BOOT . ' > /dev/null 2>&1' );

	if ( $sortie_mount != 0 ) {

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

	# Vérification de l'état du montage pour éviter des erreurs
	my $sortie_mount =
	  executer( 'findmnt ' . $BOOT . ' > /dev/null 2>&1' );

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

