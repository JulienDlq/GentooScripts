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

1;
