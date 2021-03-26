#!/bin/bash

# 2.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m1 '第1次' \
  | grep -oP '(?<=>)[^<]+(?=<)' \
  | tr , \\n \
  | tr -d \  \
  | egrep -v '[0-9]|^$' \
  | sed 1,4d \
  > 2dv2

# 3D
curl -s 'https://wikiwiki.jp/nijisanji/3Dモデルまとめ' \
  | tr -d \\n \
  | grep -oP 'n">直.*?gpt' \
  | grep -oP '(?<=>)[^<]+(?=</a></li>)' \
  | tr -d ' ' \
  > 3d

# liver
curl -s 'https://www.nijisanji.jp/members' \
  | grep -oP '(?<=<span>)[^<]+'
  > liver

# popular
echo name,popularity_rev > popular.csv
curl -s 'https://wikiwiki.jp/nijisanji/メンバーデータ一覧' \
  | tr -d \\n \
  | grep -oP '>デビュー日.*?adslot-h' \
  | sed 's/left;">/\n/g' \
  | while read -r i
    do
      echo "$(
        grep -oP '^.*?(?=<)' <<< "$i"
      ) $(
        grep -o '>-<' <<< "$i" | wc -l
      )"
    done \
  | sed '1d;/1st/d;s/(2nd)//g;s/ /,/g' \
  >> popular.csv

# res
rev_ind="$(
  sort -t , -rnk2 popular.csv | sed '1!d;s/.*,//'
)"
echo name,popularity,2d,3d > result.csv
for i in $(<liver)
do
  echo "${i},$(
    sed 1d popular.csv \
      | awk -F, "/${i}/{print 5*(${rev_ind}-\$2) | \"bc\"}"
  ),$(
    grep -q "$i" 2dv2 && echo o || echo x
  ),$(
    grep -q "$i" 3d && echo o || echo x
  )"
done \
>> result.csv
