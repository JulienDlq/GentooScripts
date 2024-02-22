#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Basename;
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

#verification_admin();

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
			'sync' => {
				'alias'  => 's',
				'usage'  => 'synchroniser et mettre à jour.',
				'defaut' => 0,
			},
			'synconly' => {
				'alias'  => 'o',
				'usage'  => 'synchroniser seulement.',
				'defaut' => 0,
			},
			'nosync' => {
				'alias'  => 'n',
				'usage'  => 'mettre à jour seulement.',
				'defaut' => 0,
			},
			'listupdate' => {
				'alias'  => 'u',
				'usage'  => 'lister les mise à jour uniquement.',
				'defaut' => 0,
			},
			'listinstalled' => {
				'alias'  => 'i',
				'usage'  => 'lister les installés uniquement.',
				'defaut' => 0,
			},
		},
	},
);

###
# Variables

my $message = {
	'ok'    => 'Tout s\'est bien passé. ;-)',
	'ko'    => 'Il y a eu un soucis… :-S',
	'na'    => 'Il y n\'y a pas de mise à jour à faire… :-O',
	'fatal' => 'Il y a eu une erreur fatale non gérée… x.x',
};

my $date = `date +%F-%H%M%S`;
chomp($date);

my $journal = {
	'dossier' => '/var/log/gentooscripts',
	'fichier' => $date . '.log',
};

my $verbose = ( $CONFIG->{'verbose'} ? ' --verbose' : '' );
my $quiet   = ' --quiet-build ' . ( $CONFIG->{'quiet'} ? 'y' : 'n' );

my $es = {
	'fonction' => 'PORTAGE::SYNC',
	'commande' => 'emaint -a sync',
};
my $euc = {
	'fonction' => 'PORTAGE::LIST::UPDATE',
	'commande' => 'eix -u -c',
};
my $eic = {
	'fonction' => 'PORTAGE::LIST::INSTALLED',
	'commande' => 'EIX_LIMIT_COMPACT=0 eix -I -c',
};
my $ewfnud = {
	'fonction' => 'PORTAGE::FETCH::WORLD ( update ; new use ; deep )',
	'commande' => 'emerge' . $verbose . ' --quiet=y -NuD --with-bdeps=y --fetch-all-uri @world',
};
my $esunud = {
	'fonction' => 'PORTAGE::EMERGE::SYSTEM ( update ; new use ; deep )',
	'commande' => 'emerge' . $verbose . $quiet . ' -NuD --with-bdeps=y @system',
};
my $ewunud = {
	'fonction' => 'PORTAGE::EMERGE::WORLD ( update ; new use ; deep )',
	'commande' => 'emerge' . $verbose . $quiet . ' -NuD --with-bdeps=y @world',
};
my $epr = {
	'fonction' => 'PORTAGE::EMERGE::PRESERVEDREBUILD',
	'commande' => 'emerge' . $verbose . $quiet . ' @preserved-rebuild',
};
my $ec = {
	'fonction' => 'PORTAGE::EMERGE::REMOVE::OBSOLETES',
	'commande' => 'emerge' . $verbose . $quiet . ' -c',
};
my $rr = {
	'fonction' => 'PORTAGE::REBUILD::DEPENDENCIES',
	'commande' => 'revdep-rebuild --' . $verbose . $quiet,
};
my $eu = {
	'fonction' => 'PORTAGE::UPDATE::ETC',
	'commande' => 'etc-update' . $verbose,
};
my $ed = {
	'fonction' => 'PORTAGE::CLEAN::DISTFILES',
	'commande' => 'eclean -v distfiles',
};

my $liste_de_maj = [ $ewfnud, $esunud, $ewunud, $ec, $epr, $rr, $eu, $ed, ];

###
# Fonctions

sub _lancer {

	my ($params) = @_;

	my $fonction = $params->{'fonction'};
	my $commande = $params->{'commande'};

	_initialise_journal_script($fonction);
	my $resultat = executer($commande);
	_message_journal_script( { 'resultat' => $resultat, 'fonction' => $fonction, } );
}

# TODO à voir s’il est nécessaire ou pas d’avoir cette sub
sub _initialise_journal_script {

	my ($fonction) = @_;

	my $log  = $journal->{'dossier'} . '/' . $journal->{'fichier'};
	my $date = `date '+%F +%T'`;
	chomp($date);

	journaliser( $fonction . ' :: DÉBUT' );
}

# TODO à voir s’il est nécessaire ou pas d’avoir cette sub
sub _finalise_journal_script {

	my ($fonction) = @_;

	my $log  = $journal->{'dossier'} . '/' . $journal->{'fichier'};
	my $date = `date '+%F +%T'`;
	chomp($date);

	#journaliser( $fonction . ' :: FIN ' . $message->{'ok'} );
}

sub _message_journal_script {

	my ($params) = @_;
	my $resultat = $params->{'resultat'};
	my $fonction = $params->{'fonction'};

	my $log  = $journal->{'dossier'} . '/' . $journal->{'fichier'};
	my $date = `date '+%F +%T'`;
	chomp($date);

	# Rappel : L’exécution de commande UNIX retourne 0 quand tout va bien
	if ( !$resultat || ( $resultat && $fonction eq $euc->{'fonction'} ) ) {
		journaliser( $fonction . ' :: FIN ' . $message->{'ok'} );
		_finalise_journal_script($fonction);
	} elsif ( $resultat && $fonction ne $euc->{'fonction'} ) {
		journaliser( $fonction . ' :: FIN ' . $message->{'ko'} );
		_finalise_journal_script($fonction);
		exit 1;
	} else {
		journaliser( $fonction . ' :: FIN ' . $message->{'fatal'} );
		_finalise_journal_script($fonction);
		exit 2;
	}
}

###
# Mise à jour

if ( $variables->{'sync'} ) {

	# Toute la suite va nécessiter des droits d’admin
	verification_admin();
	_lancer( {
		'fonction' => $es->{'fonction'},
		'commande' => $es->{'commande'},
	} );

} elsif ( $variables->{'synconly'} ) {

	# Toute la suite va nécessiter des droits d’admin
	verification_admin();
	_lancer( {
		'fonction' => $es->{'fonction'},
		'commande' => $es->{'commande'},
	} );
	exit 0;

} elsif ( $variables->{'nosync'} ) {

	# Toute la suite va nécessiter des droits d’admin
	verification_admin();

} elsif ( $variables->{'listupdate'} ) {

	_lancer( {
		'fonction' => $euc->{'fonction'},
		'commande' => $euc->{'commande'},
	} );
	exit 0;

} elsif ( $variables->{'listinstalled'} ) {

	_lancer( {
		'fonction' => $eic->{'fonction'},
		'commande' => $eic->{'commande'},
	} );
	exit 0;

} else {

	# TODO Faire bien mieux que ça…
	GentooScripts::Core::usage();
	exit 0;
}

###
# Lancement du programme principal

foreach my $index ( @{$liste_de_maj} ) {

	_lancer( {
		'fonction' => $index->{'fonction'},
		'commande' => $index->{'commande'},
	} );
}

exit 0;
