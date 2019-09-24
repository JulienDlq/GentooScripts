#!/usr/bin/env bash

# Coef pour 1920x1080 est 10
coef=10

# Tailles
top_sx=$(( 800 ))                                             # Reference
top_sy=$(( 70 * $coef ))                                      # Reference
top_px=$(( 2 * $coef ))                                       # Reference
top_py=$(( 2 * $coef ))                                       # Reference

iotop_px=$(( $top_px ))                                       # Linked to top window
iotop_py=$(( $top_py + $top_sy + 50 ))                        # Linked to top window
iotop_sx=$(( $top_sx ))                                       # Linked to top window
iotop_sy=$(( 99 * $coef - $iotop_py ))                        # Reference

ccache_sx=$(( 480 ))                                          # Reference
ccache_sy=$(( 515 ))                                          # Reference
ccache_px=$(( $top_px + $top_sx + 25 ))                       # Linked to top window
ccache_py=$(( $top_py ))                                      # Linked to top window

ccache_root_sx=$(( 480 ))                                     # Reference
ccache_root_sy=$(( $ccache_sy - 165 ))                        # Linked to ccache window
ccache_root_px=$(( $ccache_px ))                              # Linked to ccache window
ccache_root_py=$(( $iotop_py + $iotop_sy - $ccache_root_sy )) # Linked to iotop window

genlop_sx=$(( 540 ))                                          # Reference
genlop_sy=$(( 200 ))                                          # Reference
genlop_px=$(( $ccache_root_px + $ccache_root_sx + 25 ))       # Linked to ccache_root window
genlop_py=$(( $ccache_root_py + 5 * $coef ))                  # Linked to ccache_root window

sensors_sx=$(( 540 ))                                         # Reference
sensors_sy=$(( 290 ))                                         # Reference
sensors_px=$(( $ccache_px + $ccache_sx + 25 ))                # Linked to ccache window
sensors_py=$(( $ccache_py ))                                  # Linked to ccache window

df_sx=$(( 540 ))                                              # Reference
df_sy=$(( 130 ))                                              # Reference
df_px=$(( $sensors_px ))                                      # Linked to sensors window
df_py=$(( $sensors_py + $sensors_sy + 50 ))                   # Linked to sensors window

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
