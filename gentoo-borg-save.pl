#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use Cwd;
use File::Basename;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

my $REPERTOIRE_DE_TRAVAIL;
my $NOM_DU_SCRIPT;
my $CHEMIN_DU_SCRIPT;
my $CHEMIN_ABSOLUT_DU_SCRIPT;
my $LIB;

BEGIN {
	$NOM_DU_SCRIPT    = basename($0);
	$CHEMIN_DU_SCRIPT = dirname($0);

	chdir $CHEMIN_DU_SCRIPT;

	$REPERTOIRE_DE_TRAVAIL = getcwd();
	$LIB                   = $REPERTOIRE_DE_TRAVAIL . '/lib';
}

###
# Initialisation du script

use lib $LIB;
use GentooScripts::Core;

###
# Chargement de la configuration du script

require './gentoo-borg-save-config.pl';
our ( @liste_depots, $disque_sauvegarde, $depots_borgbackup, $nom_de_sauvegarde, $depots, $prune, );

my $source_passphrase = '. ./gentoo-borg-save-secret';

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
		  . ' [--nom-depot <nom du dépot>] [--nom-sauvegarde <nom du dépot>] <--liste|--info|--cree|--detruit|--sauvegarde|--supprime|--prune|--compacte|--verifie|--repare>',
		'usage_ordre' => [
			'nom-depot',  'nom-sauvegarde', 'liste', 'info',     'cree',    'detruit',
			'sauvegarde', 'supprime',       'prune', 'compacte', 'verifie', 'repare',
		],

		# Arguments et usage spécifique
		'arguments' => {
			'nom-depot' => {
				'alias' => 'd',
				'usage' => 'préciser quel dépôt doit être considéré.',
				'type'  => 's',
			},
			'nom-sauvegarde' => {
				'alias' => 'D',
				'usage' => 'préciser quelle sauvegarde doit être considéré.',
				'type'  => 's',
			},
			'liste' => {
				'alias' => 'l',
				'usage' => 'lister les dépôts disponibles'
				  . ' ou lister les sauvegardes d\'un dépôt s\'il est précisé'
				  . ' ou lister le contenu d\'une sauvegarde si elle est précisée.',
			},
			'info' => {
				'alias' => 'i',
				'usage' => 'donne des informations sur un dépôt s\'il est précisé'
				  . ' ou d\'une sauvegarde si elle est précisée.',
			},
			'cree' => {
				'alias' => 'C',
				'usage' => 'créer le dépôt sélectionné s\'il est configuré dans le fichier de configuration.',
			},
			'detruit' => {
				'alias' => 'S',
				'usage' => 'détruit le dépôt sélectionné en entier.',
			},
			'sauvegarde' => {
				'alias' => 'c',
				'usage' => 'créer une sauvegarde dans le dépôt sélectionné.',
			},
			'supprime' => {
				'alias' => 's',
				'usage' => 'supprime une sauvegarde dans le dépôt sélectionné.',
				'type'  => 's',
			},
			'prune' => {
				'alias' => 'p',
				'usage' => 'faire de la place dans le dépôt sélectionné ou dans tous les dépôts disponibles.',
			},
			'compacte' => {
				'alias' => 'P',
				'usage' => 'compacter le dépôt sélectionné ou tous les dépôts disponibles.',
			},
			'verifie' => {
				'alias' => 'r',
				'usage' => 'vérifie le dépôt sélectionné ou tous les dépôts disponibles.',
			},
			'repare' => {
				'alias' => 'R',
				'usage' => 'répare le dépôt sélectionné ou tous les dépôts disponibles.',
			},
		},
	},
);

###
# Routines

sub verification_existance_depot {

	my ($parametres) = @_;
	my $depot        = $parametres->{'nom-depot'};
	my $creation     = $parametres->{'creation'} // 0;

	if ( not exists( $depots->{$depot} ) ) {
		journaliser( 'Le dépôt ' . $depot . ' est inconnu dans la configuration.' );
		exit 0;
	}

	if ( ( not $creation ) and ( not -d $depots->{$depot}->{'chemin'} ) ) {
		journaliser( 'Le dépôt ' . $depot . ' n\'existe pas dans ' . $depots_borgbackup . '.' );
		exit 0;
	}

	if ( ($creation) and ( -d $depots->{$depot}->{'chemin'} ) ) {
		journaliser( 'Le dépôt ' . $depot . ' existe déjà dans ' . $depots_borgbackup . '.' );
		exit 0;
	}
}

sub verification_coherence_depot {

	my ($depot) = @_;

	if ( not defined($source_passphrase)
		or ( $source_passphrase eq '' ) ) {

		journaliser('le chemin de la passphrase à sourcer n\'est pas défini.');
		exit 0;
	}

	if ( not defined( $depots->{$depot}->{'nom'} )
		or ( $depots->{$depot}->{'nom'} eq '' ) ) {

		journaliser('le nom du dépôt n\'est pas défini.');
		exit 0;
	}

	if ( not defined( $depots->{$depot}->{'chemin'} )
		or ( $depots->{$depot}->{'chemin'} eq '' ) ) {

		journaliser('le chemin du dépôt n\'est pas défini.');
		exit 0;
	}

	if ( not exists( $depots->{$depot}->{'elements_a_sauver'} )
		or ( @{ $depots->{$depot}->{'elements_a_sauver'} } <= 0 ) ) {

		journaliser('les éléments à sauver sont inexistants.');
		exit 0;
	}

	if ( not defined($nom_de_sauvegarde)
		or ( $nom_de_sauvegarde eq '' ) ) {

		journaliser('le nom de la sauvegarde n\'est pas précisé');
		exit 0;
	}
}

sub lister {

	if ( defined( $variables->{'nom-depot'} ) ) {

		my $depot = $variables->{'nom-depot'};

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		my $sauvegarde;

		if ( defined( $variables->{'nom-sauvegarde'} ) ) {

			$sauvegarde = $variables->{'nom-sauvegarde'};

			journaliser(
				'Contenu de la sauvegarde ' . $sauvegarde . ' du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		} else {

			journaliser( 'Liste des sauvegardes du dépôt ' . $depots->{$depot}->{'nom'} . '.' );
		}

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg list' . ( defined($sauvegarde) ? ' ::' . $sauvegarde : '' );

	} else {

		journaliser('Liste des dépôts.');

		foreach my $depot (@liste_depots) {
			say $depot;
		}
	}

	exit 0;
}

sub informer {

	if ( defined( $variables->{'nom-depot'} ) ) {

		my $depot = $variables->{'nom-depot'};

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		my $sauvegarde;

		if ( defined( $variables->{'nom-sauvegarde'} ) ) {

			$sauvegarde = $variables->{'nom-sauvegarde'};

			journaliser( 'Donne des infos sur la sauvegarde '
				  . $sauvegarde
				  . ' du dépôt '
				  . $depots->{$depot}->{'nom'}
				  . '.' );

		} else {

			journaliser( 'Donne des infos sur le dépôt ' . $depots->{$depot}->{'nom'} . '.' );
		}

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg info' . ( defined($sauvegarde) ? ' ::' . $sauvegarde : '' );

	} else {

		journaliser('Aucun dépôt précisé.');
	}

	exit 0;
}

sub creer_depots {

	if ( defined( $variables->{'nom-depot'} ) ) {

		my $depot = $variables->{'nom-depot'};

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( {
			'nom-depot' => $depot,
			'creation'  => 1
		} );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Création du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg init -e repokey';

	} else {

		journaliser('Aucun dépôt précisé.');
	}

	exit 0;
}

sub detruit_depots {

	if ( defined( $variables->{'nom-depot'} ) ) {

		my $depot = $variables->{'nom-depot'};

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Destruction du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg delete';

	} else {

		journaliser('Aucun dépôt précisé.');
	}

	exit 0;
}

sub supprime_sauvegardes {

	if ( defined( $variables->{'nom-depot'} ) ) {

		my $depot = $variables->{'nom-depot'};

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Suppression de la sauvegarde '
			  . $variables->{'supprime'}
			  . ' du dépôt '
			  . $depots->{$depot}->{'nom'}
			  . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . ' ; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg delete ::' . $variables->{'supprime'};

	} else {

		journaliser('Aucun dépôt précisé.');
	}

	exit 0;
}

sub selectionner_depots {

	if ( defined( $variables->{'nom-depot'} ) ) {
		@liste_depots = ( $variables->{'nom-depot'} );
	}
}

sub prune_depots {

	# Parcours des différents dépôts à réduire
	foreach my $depot (@liste_depots) {

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Réduction du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande
		  . '; borg prune -v'
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
	}

	exit 0;
}

sub compacter_depots {

	# Parcours des différents dépôts à réduire
	foreach my $depot (@liste_depots) {

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Compression du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande
		  . '; borg compact -v'
		  . ' --progress';

sub verifie_depots {

	# Parcours des différents dépôts à réduire
	foreach my $depot (@liste_depots) {

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Vérification du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg check -v --progress';
	}

	exit 0;
}

sub repare_depots {

	# Parcours des différents dépôts à réduire
	foreach my $depot (@liste_depots) {

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Répare du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; borg check -v --progress --verify-data --repair';
	}

	exit 0;
}

sub sauvegarde_depots {

	# Parcours des différents dépôts à sauvegarder
	foreach my $depot (@liste_depots) {

		# Le code s'arrête si le dépot en question n'existe pas
		verification_existance_depot( { 'nom-depot' => $depot, } );

		# Le code s'arrête si le dépot en question n'est pas cohérent
		verification_coherence_depot($depot);

		journaliser( 'Sauvegarde du dépôt ' . $depots->{$depot}->{'nom'} . '.' );

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

		$commande_borg .= ' ::' . $nom_de_sauvegarde;

		my $liste_elements = '';
		foreach my $element_courant ( @{ $depots->{$depot}->{'elements_a_sauver'} } ) {
			$liste_elements .= ' ' . $element_courant;
		}

		$commande_borg .= $liste_elements;

		# Lancer la commande borg
		my $prefixe_commande = $source_passphrase . '; export BORG_REPO=' . $depots->{$depot}->{'chemin'};
		system $prefixe_commande . '; ' . $commande_borg;
	}

	exit 0;
}

###
# Lancement du programme principal

lister()               if ( $variables->{'liste'} );
informer()             if ( $variables->{'info'} );
creer_depots()         if ( $variables->{'cree'} );
detruit_depots()       if ( $variables->{'detruit'} );
supprime_sauvegardes() if ( $variables->{'supprime'} );

selectionner_depots();

prune_depots()     if ( $variables->{'prune'} );
compacter_depots() if ( $variables->{'compacte'} );

verifie_depots() if ( $variables->{'verifie'} );
repare_depots()  if ( $variables->{'repare'} );

sauvegarde_depots() if ( $variables->{'sauvegarde'} );

GentooScripts::Core::usage();

exit 0;
