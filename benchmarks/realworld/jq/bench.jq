# jq workload: filter, project and aggregate records (strings, objects,
# arrays, arithmetic, grouping).
[ .[] | select(.active and .age > 30)
  | {name, city, score: (.score * 2), ntags: (.tags | length),
     upper: (.name | ascii_upcase), initials: (.name | split(" ") | map(.[0:1]) | join(""))} ]
| group_by(.city)
| map({city: .[0].city, n: length, avg: (map(.score) | add / length),
       tags: (map(.ntags) | add), longest: (map(.upper | length) | max)})
