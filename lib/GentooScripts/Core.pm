package GentooScripts::Core;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(journaliser verification_admin executer gestion_arguments);
our @EXPORT_OK = qw();

use strict;
use warnings;
use feature 'say';
use Carp;
use Data::Dumper;

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);

# Permet d'appeler say mais avec une date locale avant
sub journaliser {
	my $texte = shift // croak('pas de texte fourni pour journaliser.');
	print "\n";
	say localtime() . ' ' . $texte;
	print "\n";
}

# Forcer les scripts à être lancés en root seulement
sub verification_admin {
	if ( getpwnam( $ENV{'USER'} ) != 0 ) {
		print 'Utiliser sudo pour lancer le script' . "\n";
		exit 1;
	}
}

# Exécuter une commande et obtenir sa sortie via la commande Perl system
sub executer {
	my $commande = shift // croak('pas de commande fournie pour executer');

	system $commande;

	if ( $? == -1 ) {
		journaliser 'Problème d\'exécution: ' . $! . '\n';
		return $?;
	} elsif ( $? & 127 ) {
		journaliser 'Le fils est mort avec le signal '
		  . ( $? & 127 ) . ', '
		  . ( ( $? & 128 ) ? 'avec' : 'sans' )
		  . ' coredump.';
		return $? & 127;
	} else {
		return $? >> 8;
	}
}

# Gestion automatique des arguments
sub gestion_arguments {

	our $configuration = shift // croak('configuration manquante.');

	our $variables = {};
	our $options   = {};

	# Construction de l'usage
	sub usage {

		say '';
		say $configuration->{'usage_general'};
		foreach my $argument ( @{ $configuration->{'usage_ordre'} } ) {
			say $configuration->{'arguments'}->{$argument}->{'usage'};
		}

		say '-h, --help             : montrer cette aide';
		say '';

		exit 0;
	}

	# Construction de la table de hash pour GetOptions
	foreach my $argument ( keys %{ $configuration->{'arguments'} } ) {

		$options->{ $argument . '|'
			  . $configuration->{'arguments'}->{$argument}->{'type'} } =
		  \$variables->{$argument};
	}

	# Ajout forcé de l'aide à la table de hash pour GetOptions
	$options->{'help|h'} = \&usage;

	# Récupération des arguments sur la ligne de commande
	GetOptions( %{$options} ) or &usage;

	# Traitement des arguments
	foreach my $argument ( keys %{ $configuration->{'arguments'} } ) {

		# Désactivation de toutes les autres variables
		# dans le cas où l'argument doit les désactiver
		if (    $configuration->{'arguments'}->{$argument}->{'desactive'}
			and $variables->{$argument} ) {
			foreach my $variable_courante ( keys %{$variables} ) {

				next if ( $variable_courante eq $argument );
				$variables->{$variable_courante} = 0;
			}
			last;
		}

		# Mise à jour des variables avec ce qui a été récupéré,
		# ou bien de la configuration
		# ou bien avec la valeur par défaut
		if ( $configuration->{'arguments'}->{$argument}->{'booleen'} ) {
			$variables->{$argument} =
			  args_oui_ou_non( $variables->{$argument}, \&usage );
		}

		$variables->{$argument} //=
		  $configuration->{'arguments'}->{$argument}->{'conf'}
		  // $configuration->{'arguments'}->{$argument}->{'defaut'};
	}

	return $variables;
}

# Traitement des options de configuration et options par défaut
sub args_oui_ou_non {

	my $choix = shift;
	my $usage = shift // croak('usage manquant.');

	if ( defined($choix) ) {

		if ( $choix eq 'oui' ) {

			return 1;
		} elsif ( $choix eq 'non' ) {

			return 0;
		} else {

			say 'Argument mal initialisé.';
			&{$usage};
		}
	} else {

		# Permet d'utiliser une valeur par défaut par la suite
		return;
	}
}

1;

