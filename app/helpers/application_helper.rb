module ApplicationHelper
  def default_meta_tags
    {
      site:        "FitGraph",
      title:       "体重・体調管理アプリ",
      reverse:     true,
      charset:     "utf-8",
      description: "FitGraphは、毎日の体重や体調をグラフで簡単に記録・管理できるWebアプリです。健康管理やダイエットの習慣化をサポートします。",
      keywords:    "体重,体調,健康管理,ダイエット,グラフ,記録,習慣化",
      canonical:   "https://www.fitgraph.jp/",
      separator:   "|",
      og: {
        site_name:  :site,
        title:      :title,
        description: :description,
        type:       "website",
        url:        "https://www.fitgraph.jp/",
        image:      image_url("OGP_icon.png", host: "https://www.fitgraph.jp"),
        secure_url: image_url("OGP_icon.png", host: "https://www.fitgraph.jp"),
        locale:     "ja_JP"
      },
      twitter: {
        card:  "summary_large_image",
        site:  "@fitgraph_app",
        image: image_url("OGP_icon.png", host: "https://www.fitgraph.jp")
      }
    }
  end
end
