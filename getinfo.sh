#!/bin/bash

set -eux

if ! command -v curl jq >/dev/null; then
  echo "install: curl. jq">&2
  exit 1
fi

if echo | grep -P "" |& grep -q "grep: invalid option" ; then
  echo "need GNU grep instead of BSD one">&2
  exit 1
fi

# Live2D 2.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m1 '第1次' \
  | grep -oE '>[^(<0-9,第]+' \
  | tr -d \> \
  | sed '1,4d;s/ギルザレンIII/ギルザレンⅢ/' \
  > 2dv2

# Live2D 3.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m2 '第1次' \
  | sed 1d \
  | grep -oE '>[^(<0-9,第]+' \
  | tr -d \> \
  | sed '1,4d;s/ギルザレンIII/ギルザレンⅢ/' \
  > 2dv3

# 3D
curl -s 'https://wikiwiki.jp/nijisanji/3Dモデルまとめ' \
  | sed -n '/<a href="#recent_presentation">/,/<a href="#videos_3d">/p' \
  | grep '</a></li>' \
  | grep -oE '>[^<]+' \
  | sed '1d;s/>//' \
  | sed 's/ //g;s/ギルザレンIII/ギルザレンⅢ/' \
  > 3d

# Liver
curl -s 'https://wikiwiki.jp/nijisanji/公式ライバー' \
  | sed -n '/<strong>公式ライバー一覧/,/star_members" title="VirtuaReal"/p' \
  | grep -v 'background-color:#ddd' \
  | sed -r '$d;s/.*title="([^"]+)".*/\1/' \
  | grep -ivE '<|>|Nijisanji|出身|VirtuaReal|ライバー' \
  | sed 's/&#23681;/岁/' \
  | sort \
  | uniq \
  > liver

# Popularity by YouTube Subs
echo name,popularity_rev > popular.csv
curl -s 'https://wikiwiki.jp/nijisanji/?cmd=popout&page=メンバーデータ一覧%2Fチャンネル登録者数&id=大台突破日' \
  | sed -z 's/text-align:left;">/@/g' \
  | tr @ \\n \
  | sed -n '/月ノ美兎/,/レンタルWIKI by/p' \
  | grep -E 'nijisanji.*title' \
  | grep -vE '1st|切り抜き|ゲーム|ASMR' \
  | while read -r i
    do
      echo "$(
        grep -oP '(?<=title=")[^"]+(?=")' <<< "$i"
      ),$(
        grep -oP 'center;">[0-9]+/[0-9]+/[0-9]+<' <<< "$i" | wc -l
      )"
    done \
  | sed 's/ギルザレンIII/ギルザレンⅢ/' \
  >> popular.csv

# Synth data and output
echo name,popularity,2dv2,2dv3,3d > result.csv
cat liver | while read i
do
  echo "${i},$(
    sed 1d popular.csv \
      | awk -F, -v name="${i}" '$1 ~ name{print 5*$2|"bc"}'
  ),$(
    grep -q "$i" 2dv2 && echo o || echo x
  ),$(
    grep -q "$i" 2dv3 && echo o || echo x
  ),$(
    grep -q "$i" 3d && echo o || echo x
  )"
done \
  | sed 's_,,_,-1,_' \
  | sort -t, -rnk2 \
  | sed 's_,-1,_,nd,_' \
  >> result.csv

# result: csv->json
sed 1d result.csv | jq -Rsn '
  {"data":
    [inputs
      | ./"\n"
      | (.[] | select(length > 0) | ./",") as $i
      | {
        "name": $i[0],
        "popularity": (if $i[1] != "nd" then $i[1] else null end),
        "2dv2": $i[2],
        "2dv3": $i[3],
        "3d": $i[4]
      }
    ]
  }' \
  > result.json
