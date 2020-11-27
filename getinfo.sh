#!/bin/bash

# 2.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | tr -d \\n \
  | grep -oP '>第1次.*?▲' \
  | grep -oP '(?<=3">)[^<]+(?=<)' \
  | tr , \\n \
  | tr -d ' ' \
  > 2dv2

# 3D
curl -s 'https://wikiwiki.jp/nijisanji/3Dモデルまとめ' \
  | tr -d \\n \
  | grep -oP 'n">直.*?gpt' \
  | grep -oP '(?<=>)[^<]+(?=</a></li>)' \
  | tr -d ' ' \
  > 3d

# liver
curl -s 'https://nijisanji.ichikara.co.jp/member/' \
  | tr -d \\n \
  | grep -oP '新規デビュー順<.*>Virtu' \
  | grep -oP '(?<=>)[^<]+(?=<)' \
  | sed '/^ *$/d' \
  | tr -d ' \t' \
  > liver

# popular
echo name,popularity_rev > popular.csv
curl -s 'https://wikiwiki.jp/nijisanji/メンバーデータ一覧' \
  | tr -d \\n \
  | grep -oP '>デビュー日.*?="model">' \
  | sed 's/left;">/\n/g' \
  | while read i
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
      | awk -F, "/${i}/{print 0.5*(${rev_ind}-\$2) | \"bc\"}" \
      | xargs printf %.1f
  ),$(
    grep -q "$i" 2dv2 && echo o || echo x
  ),$(
    grep -q "$i" 3d && echo o || echo x
  )"
done \
>> result.csv
