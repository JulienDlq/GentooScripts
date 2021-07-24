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
		journaliser 'Le fils est mort avec le signal ' . ( $? & 127 ) . ', ' . ( ( $? & 128 ) ? 'avec' : 'sans' ) . ' coredump.';
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

	# Insertion de l'aide à la fin
	push ( @{ $configuration->{'usage_ordre'} }, 'help' );
	$configuration->{'arguments'}->{'help'} = {
		'alias'  => 'h',
		'usage'  => 'montrer cette aide.',
		'defaut' => 0,
	};

	# Récupération de la taille des arguments et de la taille de l'argument le plus long
	our $taille_arguments = {};
	$taille_arguments->{'max'} = 0;

	foreach my $curr_argument ( @{ $configuration->{'usage_ordre'} } ) {
		$taille_arguments->{'arguments'}->{$curr_argument} = length($curr_argument);
		if ( $taille_arguments->{'arguments'}->{$curr_argument} > $taille_arguments->{'max'} ) {
			$taille_arguments->{'max'} = $taille_arguments->{'arguments'}->{$curr_argument};
		}
	}

	# Construction de l'usage
	sub usage {

		say '';
		say $configuration->{'usage_general'};
		foreach my $argument ( @{ $configuration->{'usage_ordre'} } ) {

			# Calcul du nombre d'espaces à insérer
			my $espaces = ' ' x ( $taille_arguments->{'max'} - $taille_arguments->{'arguments'}->{$argument} + 1 );

			say ' -'
			  . $configuration->{'arguments'}->{$argument}->{'alias'} . ', --'
			  . $argument
			  . $espaces . ': '
			  . $configuration->{'arguments'}->{$argument}->{'usage'};

		}

		say '';

		exit 0;
	}

	# Construction de la table de hash pour GetOptions
	foreach my $argument ( keys %{ $configuration->{'arguments'} } ) {

		if ( exists( $configuration->{'arguments'}->{$argument}->{'booleen'} ) ) {

			# Le bouléen étant « oui » ou « non », c'est une chaîne de caractère
			$options->{ $argument . '|' . $configuration->{'arguments'}->{$argument}->{'alias'} . '=s' } =
			  \$variables->{$argument};

		} elsif ( exists( $configuration->{'arguments'}->{$argument}->{'type'} ) ) {

			$options->{ $argument . '|' . $configuration->{'arguments'}->{$argument}->{'alias'} . '=' . $configuration->{'arguments'}->{$argument}->{'type'} }
			  = \$variables->{$argument};

		} else {

			$options->{ $argument . '|' . $configuration->{'arguments'}->{$argument}->{'alias'} } =
			  \$variables->{$argument};
		}
	}

	# Ajout forcé de l'aide à la table de hash pour GetOptions
	$options->{'help|h'} = \&usage;

	# Récupération des arguments sur la ligne de commande
	GetOptions( %{$options} ) or &usage;

	# Traitement des arguments
	foreach my $argument ( keys %{ $configuration->{'arguments'} } ) {

		if ( $configuration->{'arguments'}->{$argument}->{'booleen'} ) {
			$variables->{$argument} =
			  args_oui_ou_non( $variables->{$argument}, \&usage );
		}

		$variables->{$argument} //= $configuration->{'arguments'}->{$argument}->{'conf'} // $configuration->{'arguments'}->{$argument}->{'defaut'};
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

