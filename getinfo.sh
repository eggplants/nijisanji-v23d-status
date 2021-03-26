#!/bin/bash

# 2.0
curl -s 'https://wikiwiki.jp/nijisanji/衣装等まとめ' \
  | grep -m1 '第1次' \
  | grep -oP '(?<=>)[^<]+(?=<)' \
  | tr , \\n \
  | tr -d \  \
  | egrep -v '[0-9]|^$' \
  | sed '1,4d;s/ギルザレンIII/ギルザレンⅢ/' \
  > 2dv2

# 3D
curl -s 'https://wikiwiki.jp/nijisanji/3Dモデルまとめ' \
  | tr -d \\n \
  | grep -oP 'n">直.*?gpt' \
  | grep -oP '(?<=>)[^<]+(?=</a></li>)' \
  | sed 's/ //g;s/ギルザレンIII/ギルザレンⅢ/' \
  > 3d

# liver
curl -s 'https://www.nijisanji.jp/members' \
  | grep -oP '(?<=<span>)[^<]+' \
  > liver

# popular
echo name,popularity_rev > popular.csv
curl -s 'https://wikiwiki.jp/nijisanji/メンバーデータ一覧%2Fチャンネル登録者数' \
  | tr -d \\n \
  | grep -oP '>デビュー日.*?adslot-h' \
  | sed 's/left;">/\n/g' | sed '1d;s/ギルザレンIII/ギルザレンⅢ/' \
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

# res
echo name,popularity,2d,3d > result.csv
for i in $(<liver)
do
  echo "${i},$(
    sed 1d popular.csv \
      | awk -F, -v name="${i}" '$1 == name{print 5*$2|"bc"}'
  ),$(
    grep -q "$i" 2dv2 && echo o || echo x
  ),$(
    grep -q "$i" 3d && echo o || echo x
  )"
done \
>> result.csv
