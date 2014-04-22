#!/bin/bash
#      Copyright (C) 2005-2014 Team XBMC
#      http://www.xbmc.org
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with XBMC; see the file COPYING.  If not, write to
#  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#  http://www.gnu.org/copyleft/gpl.html

xbmcuser=$1
homedir=/home/$xbmcuser
[ -z $xbmcuser ] && homedir=$HOME
GUISETTINGS=$homedir/.xbmc/userdata/guisettings.xml

function get_device {
  if [ -f $GUISETTINGS ]
  then
    DEVICE=$(grep "<audiodevice.*>.*</audiodevice>" $GUISETTINGS | sed -e 's/\(<audiodevice.*>\)\(.*\)\(<\/audiodevice>\)/\2/g' -e 's/[\t ]//g')
  else
    echo "Error: $GUISETTINGS not found"
    exit 1
  fi
}

function check_device {
  if [ "${DEVICE:0:4}" = "ALSA" ] && [ "${DEVICE:5}" != "default" ]
  then
    DEVICE=${DEVICE:5}
    [ "${DEVICE:0:1}" = "@" ] && DEVICE="plughw:${DEVICE:2}"
  else
    echo "Error: no (or default) alsa device detected. found device: $DEVICE"
    echo "Please configure a real alsa device in Xbmc -> System -> Settings -> System -> Audio Output"
    exit 1
  fi
}

function check_asoundrc {
  if [ -f $homedir/.asoundrc ] 
  then
    local auto_update=$(grep "AUTOUPDATE=" $homedir/.asoundrc | sed 's/#.*\(AUTOUPDATE=True\).*/\1/g')
    if [ "${auto_update}" = "AUTOUPDATE=True" ]
    then
      echo "Info: $homedir/.asoundrc exists, but is marked "AUTOUPDATE=True", overwriting it"
      mv $homedir/.asoundrc $homedir/.asoundrc.bak
    else
      echo "Error: $homedir/.asoundrc exists and "AUTOUPDATE=True" not found, not modifying it"
      exit 1
    fi
  fi
}

function create_asoundrc {
  cat > $homedir/.asoundrc << EOF
# --auto-generated-- by /etc/xbmc/live.d/01-make-asoundrc.sh
# AUTOUPDATE=True  # change this to disable updating of this file
pcm.!default {
  type plug;
  slave.pcm "$DEVICE";
}
EOF

  echo "Alsa config created in $homedir/.asoundrc with following content:"
  cat $homedir/.asoundrc
  [ "$(id -u)" = "0" ] && chown $xbmcuser:$xbmcuser $homedir/.asoundrc
}

get_device
check_device
check_asoundrc
create_asoundrc
