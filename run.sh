#!/bin/sh

if which realpath >/dev/null 2>&1; then
	REALPATH="realpath"
else
	REALPATH="readlink -f"
fi

if [ -n "$1" ]; then
	FILTER="$1"
else
	FILTER="*"
fi

[ -z "$TEST_TMUX" ] && TEST_TMUX=../tmux/tmux
[ -x "$TEST_TMUX" ] || exit 1

TEST_TMUX="$($REALPATH $TEST_TMUX)"
[ -x "$TEST_TMUX" ] || exit 1

echo tmux is $TEST_TMUX
TMUX_L="$TEST_TMUX -L__tests__ -f/dev/null"
$TMUX_L has 2>/dev/null && $TMUX_L kill-server

ROOT="$($REALPATH tests)"
TESTS="$(cd $ROOT && find * -type f -name \*.test|sort)"

for this in $TESTS; do
	[ ! -x "$ROOT/$this" ] && continue

	case "$this" in
		$FILTER)
			;;
		*)
			continue
			;;
	esac

	name="${this%.test}"
	printf "%-32s" "$name"
	
	out="$ROOT/$name.out"
	env -i TMUX_L="$TMUX_L" TMUX_CONF="$ROOT/$name.conf" \
	    sh "$ROOT/$this" >"$out"
	if [ $? -ne 0 ]; then
		result="failed"
	elif ! cmp  -s "$out" "$ROOT/$name.expected"; then
		result="bad"
	else
		result="good"
		rm -f "$out"
	fi
	printf "%s\n" "$result"

	$TMUX_L kill-server 2>/dev/null
	while $TMUX_L kill-server 2>/dev/null; do
		sleep 1
	done
done
