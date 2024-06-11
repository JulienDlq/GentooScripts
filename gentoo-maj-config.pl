use strict;
use warnings;

# Configuration du script
our $CONFIG = {
	'verbose'   => 0,     # Pas de verbose (0)
	'quiet'     => 1,     # Pas de messages de compilation sur la sortie standard (1)
	'force'     => 0,     # Pas de force de la mise à jour (0)
	'backtrack' => 30,    # Configuration du backtrack d’emerge (30)
};

1;

