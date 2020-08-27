#!/usr/bin/env bash

# Coef pour 1920x1080 est 10
coef=10

# Tailles
top_sx=$(( 700 ))                                               # Reference
top_sy=$(( 65 * $coef ))                                        # Reference
top_px=$(( 20 ))                                                # Reference
top_py=$(( 20 ))                                                # Reference

iotop_sx=$(( $top_sx ))                                         # Linked to top window
iotop_sy=$(( 13 * $coef ))                                      # Reference
iotop_px=$(( $top_px ))                                         # Linked to top window
iotop_py=$(( $top_py + $top_sy + 50 ))                          # Linked to top window

df_sx=$(( $iotop_sx ))                                          # Linked to iotop window
df_sy=$(( 10 * $coef ))                                         # Reference
df_px=$(( $iotop_px ))                                          # Linked to iotop window
df_py=$(( $iotop_py + $iotop_sy + 50 ))                         # Linked to iotop window

ccache_sx=$(( 480 ))                                            # Reference
ccache_sy=$(( 515 ))                                            # Reference
ccache_px=$(( $top_px + $top_sx + 20 ))                         # Linked to top window
ccache_py=$(( $top_py ))                                        # Linked to top window

ccache_root_sx=$(( 480 ))                                       # Reference
ccache_root_sy=$(( $ccache_sy - 165 ))                          # Linked to ccache window
ccache_root_px=$(( $ccache_px ))                                # Linked to ccache window
ccache_root_py=$(( $df_py + $df_sy - $ccache_root_sy ))         # Linked to df window

sensors_sx=$(( 660 ))                                           # Reference
sensors_sy=$(( 73 * $coef ))                                    # Reference
sensors_px=$(( $ccache_px + $ccache_sx + 20 ))                  # Linked to ccache window
sensors_py=$(( $ccache_py ))                                    # Linked to ccache window

genlop_sx=$(( $sensors_sx ))                                    # Linked to sensors window
genlop_sy=$(( 200 ))                                            # Reference
genlop_px=$(( $ccache_root_px + $ccache_root_sx + 20 ))         # Linked to ccache_root window
genlop_py=$(( $ccache_root_py + $ccache_root_sy - $genlop_sy )) # Linked to ccache_root window


# Il faut ajouter les lignes suivantes dans le fichier /etc/sudoers afin de ne pas avoir à fournir le mot de passe à sudo
# %wheel ALL=(ALL) NOPASSWD: /usr/bin/watch -n1 -- ccache -s
# %wheel ALL=(ALL) NOPASSWD: /usr/bin/iotop -o
# %wheel ALL=(ALL) NOPASSWD: /usr/bin/watch -n1 -c -- genlop -c

# Commandes
konsole -qwindowgeometry ${top_sx}x${top_sy}+${top_px}+${top_py} -e 'top' &
konsole -qwindowgeometry ${iotop_sx}x${iotop_sy}+${iotop_px}+${iotop_py} -e 'sudo iotop -o' &
konsole -qwindowgeometry ${ccache_sx}x${ccache_sy}+${ccache_px}+${ccache_py} -e 'watch -n1 -- CCACHE_DIR=/var/tmp/ccache/ ccache -s' &
konsole -qwindowgeometry ${ccache_root_sx}x${ccache_root_sy}+${ccache_root_px}+${ccache_root_py} -e 'sudo watch -n1 -- ccache -s' &
konsole -qwindowgeometry ${genlop_sx}x${genlop_sy}+${genlop_px}+${genlop_py} -e 'sudo watch -n1 -c -- genlop -c' &
konsole -qwindowgeometry ${sensors_sx}x${sensors_sy}+${sensors_px}+${sensors_py} -e 'watch -n1 -c -- sensors' &
konsole -qwindowgeometry ${df_sx}x${df_sy}+${df_px}+${df_py} -e 'watch -n1 -- "df -h | grep portage ; echo ; df | grep portage"' &

exit 0

