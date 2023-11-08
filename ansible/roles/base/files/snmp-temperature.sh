#!/usr/bin/env sh
# https://bestmonitoringtools.com/snmpwalk-example-v3-v2-snmpget-snmpset-snmptrap/#snmpwalk_v3_example
# https://paulierco.ro/add-temperature-and-fan-data-to-snmp-edgerouter.html
# https://github.com/bryanalves/edgerouter_snmp_exporter/blob/master/generator.yml
# https://github.com/prometheus/snmp_exporter/blob/main/generator/Makefile
# https://community.ui.com/questions/EdgePoint-SNMP-temperature-OID-strings/7d643802-6330-4bf7-b419-c636f51151cd
testdata() {
    cat <<'EOF'
Temperature:
CPU:54.50 C
Board 1:52.75 C
Board 2:41.75 C
PHY 1:72.12 C
PHY 2:54.75 C
EOF
}

base=".1.3.6.1.4.1.4413.1.1.43.1.8.1.5.1"

# /usr/sbin/ubnt-hall getTemp |


get() {
  testdata | awk -F: '{if ($2) {
    gsub(" C", "", $2);
    gsub(" ", "-", $1)
    print $1, $2
  }}' | while read -r kind reading; do
    degs_round="$(printf '%.0f' "$reading")"
    index=""
    case "$kind" in
      "Board-"*)
        # 0 and 1
        board="${kind##*-}"
        index=$(( board - 1))
        ;;
      "PHY-"*)
        # 2 and 3
        iface="${kind##*-}"
        index=$(( 1 + iface ))
        ;;
      CPU)
        index=4
        ;;
      *)
        echo "unknown kind: $kind"
        continue;;
    esac
    echo "$base.$index"
    echo "integer"
    echo "$degs_round"
  done
}

get_index() {
  index="$1" filter=""
  case "$index" in
    0|1) filter="Board $(( index + 1 ))" ;;
    2|3) filter="PHY $(( index - 1 ))" ;;
    4) filter="CPU" ;;
    *) exit 0
  esac

  reading=$(testdata | awk -F: '/^'"$filter"'/{ gsub(" C", "", $2); print $2 }')
  echo "$base.$index"
  echo "integer"
  printf '%.0f\n' "$reading"
}


oid="$2"
case "$1" in
  -g)
    get_index "${oid##*.}" ;;
  -n)
    index=""
    if [ "$oid" = "$base" ]; then
      index="0"
    else
      index="${oid##*.}"
      index=$(( index + 1 ))
    fi

    get_index "$index" ;;
  *) echo "bad usage" >&2; exit 2 ;;
esac
