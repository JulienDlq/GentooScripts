use strict;
use warnings;
use feature 'say';
use Carp;

# Permet d'appeler say mais avec une date locale avant
sub journaliser {
    my $texte = shift // croak 'pas de texte fourni pour journaliser.';
    print "\n";
    say localtime() . ' ' . $texte;
    print "\n";
}

# Forcer les scripts à être lancés en root seulement
sub verification_admin {
    if( getpwnam($ENV{'USER'}) != 0 ) {
        print 'Utiliser sudo pour lancer le script' . "\n";
        exit 1;
    }
}

# Exécuter une commande et obtenir sa sortie via la commande Perl system
sub executer {
    my $commande = shift // croak 'pas de commande fournie pour executer';

    system $commande;

    if ( $? == -1 ) {
        journaliser 'Problème d\'exécution: ' . $! . '\n';
        return $?;
    }
    elsif ( $? & 127 ) {
        journaliser 'Le fils est mort avec le signal '
          . ( $? & 127 ) . ', '
          . ( ( $? & 128 ) ? 'avec' : 'sans' )
          . ' coredump.';
        return $? & 127;
    }
    else {
        return $? >> 8;
    }
}

1;
