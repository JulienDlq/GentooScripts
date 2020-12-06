use strict;
use warnings;

# Liste des dépôts borg à considérer pour les sauvegardes
our @liste_depots = ( 'system' );

our $disque_sauvegarde = '<inserer ici le chemin du disque de sauvegarde>';
our $depots_borgbackup = $disque_sauvegarde . '<insérer ici le chemin du dossier de sauvegarde borg>';
our $nom_de_sauvegarde = '{now}';

our $depots = {
    'system' => {
        'nom'               => 'Système',
        'chemin'            => $depots_borgbackup . '/system',
        'verbose'           => 1,
        'stats'             => 1,
        'progress'          => 1,
        'one_file_system'   => 1,
        'compression'       => 'zstd,22',
        'exclude_caches'    => 1,
        'exclude'           => '/root/.cache/*',
        'elements_a_sauver' => [
            '/etc',             '/usr/src',
            '/var/lib/portage', '/var/lib/layman',
            '/root',
        ],
    },
};

1;
