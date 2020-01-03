---
layout: mylayout
---


- {{ "tspage" | refer | refer_link }}
- {{ "hoge" | refer | refer_link }}
- {{ "test-post" | refer | refer_link }}


# include_content hoge

{{ "hoge" | refer | include_content }}

# include_content tspage

{{ "tspage" | refer | include_content }}

# include_content tspage

{{ "tspage" | refer | include_content: "include_layout" }}

# include_content tspage

{{ "tspage" | refer | include_content: nil }}

# include_content test-post

{{ "test-post" | refer | include_content }}
