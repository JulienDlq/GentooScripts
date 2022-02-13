use strict;
use warnings;

# Liste des dépôts borg à considérer pour les sauvegardes
our @liste_depots = ('test');

our $disque_sauvegarde = '/';
our $depots_borgbackup = $disque_sauvegarde . 'tmp';
our $nom_de_sauvegarde = '{now}';

our $depots = {
	'test' => {
		'nom'               => 'Test',
		'chemin'            => $depots_borgbackup . '/test',
		'verbose'           => 1,
		'stats'             => 1,
		'progress'          => 1,
		'one_file_system'   => 1,
		'compression'       => 'zstd,22',
		'exclude_caches'    => 1,
		'exclude'           => undef,
		'elements_a_sauver' => [ '/etc', ],
	},
};

our $prune = {
	'hourly'  => 6,
	'daily'   => 1,
	'weekly'  => 1,
	'monthly' => 1,
	'yearly'  => 1,
};

1;
