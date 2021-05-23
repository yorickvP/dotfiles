NO_OUTPUTS=$(swaymsg -t get_outputs | jq 'length')
IFS='	'
paste <(find ~/wp/ -type f | shuf | head -n$NO_OUTPUTS) <(swaymsg -t get_outputs | jq -r 'map(.name)|.[]') | while read file output; do
    swaymsg output $output bg "$file" stretch
done
