#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

linux_acpi() {
  arg=$1
  BAT=$(ls -d /sys/class/power_supply/*)
  if [ ! -x "$(which acpi 2>/dev/null)" ]; then
    case "$arg" in
    status)
      cat $BAT/status
      ;;

    percent)
      cat $BAT/capacity
      ;;

    *) ;;
    esac
  else
    case "$arg" in
    status)
      acpi | cut -d: -f2- | cut -d, -f1 | tr -d ' '
      ;;
    percent)
      acpi | cut -d: -f2- | cut -d, -f2 | tr -d '% '
      ;;
    *) ;;
    esac
  fi
}

battery_percent() {
  # Check OS
  case $(uname -s) in
  Linux)
    percent=$(linux_acpi percent)
    [ -n "$percent" ] && echo "$percent"
    ;;

  Darwin)
    echo $(pmset -g batt | grep -Eo '[0-9]?[0-9]?[0-9]%')
    ;;

  FreeBSD)
    echo $(apm | sed '8,11d' | grep life | awk '{print $4}')
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    # leaving empty - TODO - windows compatability
    ;;

  *) ;;
  esac
}

# # battery_status can be 'discharging', 'charging', 'charged'
# battery_status() {
#   # Check OS
#   case $(uname -s) in
#   Linux)
#     status=$(linux_acpi status)
#     if [ -z "$status" ]; then
#       status=$(cat /sys/class/power_supply/BAT*/status)
#     fi
#     ;;

#   Darwin)
#     status=$(pmset -g batt | sed -n 2p | cut -d ';' -f 2 | tr -d " ")
#     ;;

#   FreeBSD)
#     status=$(apm | sed '8,11d' | grep Status | awk '{printf $3}')
#     ;;

#   CYGWIN* | MINGW32* | MSYS* | MINGW*)
#     # leaving empty - TODO - windows compatability
#     ;;

#   *) ;;
#   esac

#   case $status in
#   discharging | Discharging)
#     echo ''
#     ;;
#   high | Full)
#     echo ''
#     ;;
#   charging | Charging)
#     echo '󱐋'
#     ;;
#   *)
#     echo '󱐋'
#     ;;
#   esac
#   ### Old if statements didn't work on BSD, they're probably not POSIX compliant, not sure
#   # if [ $status = 'discharging' ] || [ $status = 'Discharging' ]; then
#   # 	echo ''
#   # # elif [ $status = 'charging' ]; then # This is needed for FreeBSD AC checking support
#   # 	# echo 'AC'
#   # else
#   #  	echo 'AC'
#   # fi
# }

main() {
  ac_is_plugged=$(upower -i $(upower -e | grep AC) | grep online | awk '{print $2}' | grep -c "yes")
  ac_plugged_icon="󱐥 "
  ac_not_plugged_icon="󱐤 "

  ac_icon=$ac_not_plugged_icon
  if [ $ac_is_plugged -eq 1 ]; then
    ac_icon=$ac_plugged_icon
  fi

  bat_chrg=$(upower -i $(upower -e | grep BAT) | grep state | awk '{print $2}' | grep -c "charging")
  bat_perc=$(battery_percent)

  bat_icon_1_4="󰂎 "
  bat_icon_2_4="󱊡 "
  bat_icon_3_4="󱊢 "
  bat_icon_4_4="󱊣 "
  bat_icon_ac_1_4="󰢟 "
  bat_icon_ac_2_4="󱊤 "
  bat_icon_ac_3_4="󱊥 "
  bat_icon_ac_3_4="󱊦 "

  bat_icon=$bat_icon_4_4

  if [ $bat_perc -gt 75 ]; then
    bat_icon=$bat_icon_4_4
  elif [ $bat_perc -gt 50 ]; then
    bat_icon=$bat_icon_3_4
  elif [ $bat_perc -gt 25 ]; then
    bat_icon=$bat_icon_2_4
  elif [ $bat_perc -gt 10 ]; then
    bat_icon=$bat_icon_1_4
  fi

  echo "$ac_icon$bat_icon$bat_perc"
}

#run main driver program
main
