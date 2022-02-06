#!/bin/bash

command -v curl jq >/dev/null || {
  echo "install :curl, jq">&2
  exit 1
}

echo | grep -P "" |& grep -q "grep: invalid option" && {
  echo "Required grep impl is GNU. BSD is useless.">&2
  exit 1
}

# Live2D 2.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m1 '第1次' \
  | sed -nE 's/[^>]+>([^<]+)</\1'$'\\n/gp' \
  | sed 's_^/td><td>_,'$'\\n_' \
  | grep -A1 "^," \
  | sed -E "/,|--/d" \
  | sed 's/ギルザレンIII/ギルザレンⅢ/' \
  > 2dv2

# Live2D 3.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m2 '第1次' \
  | sed 1d \
  | sed -nE 's/[^>]+>([^<]+)</\1'$'\\n/gp' \
  | sed 's_^/td><td>_,'$'\\n_' \
  | grep -A1 "^," \
  | sed -E "/,|--/d" \
  | sed 's/ギルザレンIII/ギルザレンⅢ/' \
  > 2dv3

# 3D
curl -s 'https://wikiwiki.jp/nijisanji/3Dモデルまとめ' \
  | sed -n '/<a href="#recent_presentation">/,/<a href="#videos_3d">/p' \
  | sed -nE '/<li><a href="#[A-Z]/s/^.*>([^<]+)<.*$/\1/p' \
  | sed 's/ //g;s/ギルザレンIII/ギルザレンⅢ/' \
  > 3d

# Liver
curl -s 'https://www.nijisanji.jp/members' \
  | sed -nE 's_.*type="application/json">([^<]+)<.*_\1_p' \
  | jq -r '[
      .props.pageProps.livers[]
      |select(.affiliation|index("にじさんじ"))
      |{n:.name,s:.subscribe_orders}
    ]|sort_by(.s)[]|.n' \
  > liver

# Popularity by YouTube Subs
echo name,popularity_rev > popular.csv
curl -s 'https://wikiwiki.jp/nijisanji/メンバーデータ一覧%2Fチャンネル登録者数' \
  | tr -d \\n \
  | grep -oP '>デビュー日.*?adslot-h' \
  | sed 's/left;">/\n/g' \
  | sed '1d;s/ギルザレンIII/ギルザレンⅢ/' \
  | sed 's/^.*rel-wiki-page">//' \
  | while read -r i
    do
      echo "$(
        grep -oP '^.*?(?=<)' <<< "$i"
      ) $(
        grep -oP '>[0-9]+日<' <<< "$i" | wc -l
      )"
    done \
  | sed '1d;/1st/d;s/(2nd)//g;s/ /,/g' \
  >> popular.csv

# Synth data and output
echo name,popularity,2dv2,2dv3,3d > result.csv
for i in $(<liver)
do
  echo "${i},$(
    sed 1d popular.csv \
      | awk -F, -v name="${i}" '$1 == name{print 5*$2|"bc"}'
  ),$(
    grep -q "$i" 2dv2 && echo o || echo x
  ),$(
    grep -q "$i" 2dv3 && echo o || echo x
  ),$(
    grep -q "$i" 3d && echo o || echo x
  )"
done \
>> result.csv

# result: csv->json
sed 1d result.csv | jq -Rsn '
  {"data":
    [inputs
      | ./"\n"
      | (.[] | select(length > 0) | ./",") as $i
      | {
        "name": $i[0],
        "popularity": $i[1],
        "2dv2": $i[2],
        "2dv3": $i[3],
        "3d": $i[4]
      }
    ]
  }' \
  > result.json
