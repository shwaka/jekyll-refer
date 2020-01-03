---
layout: mylayout
---

# about this
`jekyll-typescript` で生成したページ ({{ "tspage" | refer | refer_link }})
を `include_md` でインクルードした結果が下のようになる．
生成された内容が反映されていない．

- {{ "tspage" | refer | refer_link }}
- {{ "hoge" | refer | refer_link }}


# include_md tspage

{{ "tspage" | refer | include_md }}
