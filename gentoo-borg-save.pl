#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Basename;
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

###
# Chargement de la configuration du script

require './gentoo-borg-save-config.pl';
our ( @liste_depots, $disque_sauvegarde, $depots_borgbackup,
	$nom_de_sauvegarde, $depots, $prune, );

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
		  . ' [--depot <nom du dépot>] [--liste|--prune]',
		'usage_ordre' => [ 'depot', 'liste', 'prune', ],

		# Arguments et usage spécifique
		'arguments' => {
			'depot' => {
				'usage' => '-d, --depot dépôt : '
				  . 'préciser quel dépôt doit être considéré.',
				'type' => 'd=s',
			},
			'liste' => {
				'usage' => '-l, --liste       : '
				  . 'lister les dépôts disponibles ou la liste des sauvegarde d\'un dépôt s\'il est précisé.',
				'type' => 'l',
			},
			'prune' => {
				'usage' => '-p, --prune       : '
				  . 'faire de la place dans le dépôt sélectionné ou dans tous les dépôts disponibles.',
				'type' => 'p',
			},
		},
	},
);

###
# Lancement du programme principal

my $source_passphrase = '. ./gentoo-borg-save-secret';

if ( $variables->{'liste'} ) {

	if ( defined( $variables->{'depot'} ) ) {

		my $depot = $variables->{'depot'};

		# Vérifier l'existance de la configuration du dépôt en question
		if ( not exists( $depots->{$depot} ) ) {
			journaliser( 'Le dépôt ' . $depot . ' est inconnu.' );
		} else {

			if ( defined( $depots->{$depot}->{'nom'} )
				and ( $depots->{$depot}->{'nom'} ne '' ) ) {
				journaliser( 'Liste des sauvegardes du dépôt '
					  . $depots->{$depot}->{'nom'}
					  . '.' );
			} else {
				croak 'le nom du dépôt n\'est pas défini.';
			}

	# Construction de la commande borg à utiliser pour le dépôt sélectionné
			my $commande_borg = 'borg list';

			if ( defined( $depots->{$depot}->{'chemin'} )
				and ( $depots->{$depot}->{'chemin'} ne '' ) ) {
				$commande_borg =
					'export BORG_REPO='
				  . $depots->{$depot}->{'chemin'} . '; '
				  . $commande_borg;
			} else {
				croak 'le chemin du dépôt n\'est pas défini.';
			}

			if ( defined($source_passphrase)
				and ( $source_passphrase ne '' ) ) {
				$commande_borg = $source_passphrase . '; ' . $commande_borg;
			} else {
				croak
				  'le chemin de la passphrase à sourcer n\'est pas défini.';
			}

			# Lancer la commande borg
			#journaliser( $commande_borg );
			system $commande_borg;
		}
		exit 0;
	} else {
		foreach my $depot (@liste_depots) {
			say $depot;
		}

		exit 0;
	}

}

# Sélection des différents dépôts à sauvegarder et/ou à réduire
if ( defined( $variables->{'depot'} ) ) {
	@liste_depots = ( $variables->{'depot'} );
}

# Parcours des différents dépôts à sauvegarder
if ( not $variables->{'prune'} ) {

	foreach my $depot (@liste_depots) {

		# Vérifier l'existance de la configuration du dépôt en question
		if ( not exists( $depots->{$depot} ) ) {
			journaliser( 'Le dépôt ' . $depot . ' est inconnu.' );
		} else {

			if ( defined( $depots->{$depot}->{'nom'} )
				and ( $depots->{$depot}->{'nom'} ne '' ) ) {
				journaliser( 'Sauvegarde du dépôt '
					  . $depots->{$depot}->{'nom'}
					  . '.' );
			} else {
				croak 'le nom du dépôt n\'est pas défini.';
			}

	# Construction de la commande borg à utiliser pour le dépôt sélectionné
			my $commande_borg = 'borg create';

			if ( exists( $depots->{$depot}->{'verbose'} ) ) {
				$commande_borg .=
				  ( $depots->{$depot}->{'verbose'} ? ' --verbose' : '' );
			}

			if ( exists( $depots->{$depot}->{'stats'} ) ) {
				$commande_borg .=
				  ( $depots->{$depot}->{'stats'} ? ' --stats' : '' );
			}

			if ( exists( $depots->{$depot}->{'progress'} ) ) {
				$commande_borg .=
				  ( $depots->{$depot}->{'progress'} ? ' --progress' : '' );
			}

			if ( exists( $depots->{$depot}->{'one_file_system'} ) ) {
				$commande_borg .= (
					$depots->{$depot}->{'one_file_system'}
					? ' --one-file-system'
					: ''
				);
			}

			if ( exists( $depots->{$depot}->{'compression'} ) ) {
				$commande_borg .= (
					$depots->{$depot}->{'compression'}
					? ' --compression ' . $depots->{$depot}->{'compression'}
					: ''
				);
			}

			if ( exists( $depots->{$depot}->{'exclude_caches'} ) ) {
				$commande_borg .= (
					$depots->{$depot}->{'exclude_caches'}
					? ' --exclude-caches'
					: ''
				);
			}

			if ( exists( $depots->{$depot}->{'exclude'} ) ) {
				$commande_borg .= (
					$depots->{$depot}->{'exclude'}
					? ' --exclude \'' . $depots->{$depot}->{'exclude'} . '\''
					: ''
				);
			}

			if ( defined($nom_de_sauvegarde)
				and ( $nom_de_sauvegarde ne '' ) ) {
				$commande_borg .= ' ::' . $nom_de_sauvegarde;
			} else {
				croak 'le nom de la sauvegarde n\'est pas précisé';
			}

			if ( exists( $depots->{$depot}->{'elements_a_sauver'} )
				and ( @{ $depots->{$depot}->{'elements_a_sauver'} } > 0 ) ) {

				my $liste_elements = '';

				foreach my $element_courant (
					@{ $depots->{$depot}->{'elements_a_sauver'} } ) {
					$liste_elements .= ' ' . $element_courant;
				}

				$commande_borg .= $liste_elements;

			} else {
				croak 'les éléments à sauver sont inexistants.';
			}

			if ( defined( $depots->{$depot}->{'chemin'} )
				and ( $depots->{$depot}->{'chemin'} ne '' ) ) {
				$commande_borg =
					'export BORG_REPO='
				  . $depots->{$depot}->{'chemin'} . '; '
				  . $commande_borg;
			} else {
				croak 'le chemin du dépôt n\'est pas défini.';
			}

			if ( defined($source_passphrase)
				and ( $source_passphrase ne '' ) ) {
				$commande_borg = $source_passphrase . '; ' . $commande_borg;
			} else {
				croak
				  'le chemin de la passphrase à sourcer n\'est pas défini.';
			}

			# Lancer la commande borg
			#journaliser( $commande_borg );
			system $commande_borg;
		}
	}
}

# Parcours des différents dépôts à réduire
foreach my $depot (@liste_depots) {

	# Vérifier l'existance de la configuration du dépôt en question
	if ( not exists( $depots->{$depot} ) ) {
		journaliser( 'Le dépôt ' . $depot . ' est inconnu.' );
	} else {

		if ( defined( $depots->{$depot}->{'nom'} )
			and ( $depots->{$depot}->{'nom'} ne '' ) ) {
			journaliser(
				'Réduction du dépôt ' . $depots->{$depot}->{'nom'} . '.' );
		} else {
			croak 'le nom du dépôt n\'est pas défini.';
		}

	# Construction de la commande borg à utiliser pour le dépôt sélectionné
		my $commande_borg =
			'borg prune -v'
		  . ' --list'
		  . ' --stats'
		  . ' --keep-hourly='
		  . ( $prune->{'hourly'} // 1 )
		  . ' --keep-daily='
		  . ( $prune->{'daily'} // 1 )
		  . ' --keep-weekly='
		  . ( $prune->{'weekly'} // 1 )
		  . ' --keep-monthly='
		  . ( $prune->{'monthly'} // 1 )
		  . ' --keep-yearly='
		  . ( $prune->{'yearly'} // 1 );

		if ( defined( $depots->{$depot}->{'chemin'} )
			and ( $depots->{$depot}->{'chemin'} ne '' ) ) {
			$commande_borg =
				'export BORG_REPO='
			  . $depots->{$depot}->{'chemin'} . '; '
			  . $commande_borg;
		} else {
			croak 'le chemin du dépôt n\'est pas défini.';
		}

		if ( defined($source_passphrase)
			and ( $source_passphrase ne '' ) ) {
			$commande_borg = $source_passphrase . '; ' . $commande_borg;
		} else {
			croak 'le chemin de la passphrase à sourcer n\'est pas défini.';
		}

		# Lancer la commande borg
		#journaliser( $commande_borg );
		system $commande_borg;
	}
}

exit 0;

