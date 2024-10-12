#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Carp;
use File::Basename;

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
# Toute la suite va nécessiter des droits d'admin

verification_admin();

###
# Variables

my $compilations_connues = {};

###
# Fonctions

sub recuperation_compilations_en_cours {

	# Récupération des compilations en cours
	my @compilations_en_cours_brutes = `find /var/tmp/portage -mindepth 2 -maxdepth 2 -type d`;

	# Préparation du stockage des compilations en cours (nettoyées de leurs caractères inutiles)
	my @compilations_en_cours_propres = ();

	# Suppression des caractères inutiles au début et à la fin et stockage
	foreach my $nom (@compilations_en_cours_brutes) {
		chomp($nom);                                     # Suppression du saut de ligne final
		push( @compilations_en_cours_propres, $nom );    # Stockage
	}

	# Transformation pour exploitation et retour
	return map { $_ => undef } @compilations_en_cours_propres;
}

sub mise_a_jour_compilations_connues {

	my ($params) = @_;
	my $compilations_a_analyser = $params->{'compilations'};

	# Il faut chercher chacune des compilations connues
	# dans la liste des compilations à analyser
	foreach my $element ( sort keys %{$compilations_connues} ) {

		# À ce moment, deux possibilités :
		# - soit la compilation existe
		# - soit la compilation n’existe pas
		if ( exists( $compilations_a_analyser->{$element} ) ) {

			# Quand la compilation est trouvée
			# dans la liste des compilations à analyser,
			# il est nécessaire de supprimer
			# la compilation correspondante puisque le tail
			# correspondant à cette compilation tourne déjà
			delete $compilations_a_analyser->{$element};

		} else {

			# Quand la compilation n’est pas trouvée
			# dans la liste des compilations à analyser,
			# il est nécessaire de mettre à jour le statut
			# de la compilation dans la liste des compilations connues
			# Il faut arrêter le tail correspondant à cette compilation
			$compilations_connues->{$element}->{'statut'} = 'arreter';
		}
	}

	# Il faut chercher chacune des nouvelles compilations inconnues
	# dans la liste des compilations à analyser
	foreach my $element ( sort keys %{$compilations_a_analyser} ) {

		# Quand la compilation est inconnue
		# dans la liste des compilations à analyser,
		# il est nécessaire de mettre à jour le statut
		# de la compilation dans la liste des compilations connues
		# Il faut lancer le tail correspondant à cette compilation
		$compilations_connues->{$element}->{'statut'} = 'lancer';
	}
}

###
# Programme principal

# La surveillance se fait en continu jusqu’à l’arrêt du programme par l’utilisateur (CTRL+C)
do {

	# Récupération des paquets en cours de compilation
	my %compilations_en_cours = recuperation_compilations_en_cours();

	# Mise à jour des états des compilations connues
	mise_a_jour_compilations_connues( { 'compilations' => \%compilations_en_cours } );

	# Traitement des états des compilations connues
	foreach my $element ( sort keys %{$compilations_connues} ) {

		# Deux cas vont se présenter :
		# - soit il faut lancer le tail correspondant
		# - soit il faut tuer le tail correspondant
		if ( $compilations_connues->{$element}->{'statut'} eq 'lancer' ) {

			# Division effective pour lancer le tail
			my $pid = fork;
			die "division ratée : $!" unless defined $pid;

			# Le fils lance le tail
			if ( $pid == 0 ) {

				# Cloture de la sortie d’erreur,
				# pour éviter que tail ne se plaigne
				# de la non-existance du fichier
				# avant qu’il se fasse arrêter
				close(STDERR);

				# Exécution effective de tail
				exec('tail -n0 -F ' . $element . '/temp/build.log') or print STDERR "impossible d’exécuter la commande : $!";
				exit 0;
			}

			# Récupération du PID
			$compilations_connues->{$element}->{'PID'} = $pid;

			# Changer d’état
			$compilations_connues->{$element}->{'statut'} = 'tourne';

		} elsif ( $compilations_connues->{$element}->{'statut'} eq 'arreter' ) {

			# Arrêter le processus tail correspondant
			kill('TERM', $compilations_connues->{$element}->{'PID'});

			# Attendre de manière non bloquante
			# que tous les enfants soient bien arrêtés
			waitpid( -1, 0 );

			# Supprimer la compilation correspondante
			# de la liste des compilations connues
			delete $compilations_connues->{$element};
		}
	}

	# Attente pour éviter de trop charger le système
	sleep(1);

} while (1);

exit 0;
