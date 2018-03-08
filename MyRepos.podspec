Pod::Spec.new do |s|
  s.name         = "MyRepos" # 项目名称
  s.version      = "1.0.0"        # 版本号 与 你仓库的 标签号 对应
  s.license      = "MIT"          # 开源证书
  s.summary      = "MyRepos" # 项目简介

  s.homepage     = "https://github.com/LymZy/MyRepos" # 你的主页
  s.source       = { :git => "https://github.com/LymZy/MyRepos.git", :tag => s.version }#你的仓库地址，不能用SSH地址
  s.source_files = "MyRepos/*.{h,m}" # 你代码的位置，
  s.requires_arc = true # 是否启用ARC
  s.platform     = :ios, "7.0" #平台及支持的最低版本
  s.frameworks   = "UIKit", "Foundation" #支持的框架
  #s.dependency "MBProgressHUD" # 依赖库
  #s.dependencies = "Masonry"
  # User
  s.author             = { "Lym" => "377342167@qq.com" } # 作者信息
  s.social_media_url   = "https://github.com/LymZy/MyRepos" # 个人主页

end
