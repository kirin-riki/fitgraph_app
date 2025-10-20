# lib/tasks/assets.rake
# Rails の assets:precompile 実行時に自動的に CSS/JS をビルド

namespace :assets do
  desc "Build CSS and JS before precompiling assets"
  task :build do
    # 重要: JSを先にビルドし、その後CSSをビルドする
    # esbuildがMaterial Icons CSSをapplication.cssとして出力するが、
    # 後からPostCSSでTailwind CSSを上書きすることで正しいCSSを確保する

    puts "Building JS with esbuild..."
    sh "yarn build"

    puts "Building CSS with PostCSS..."
    sh "yarn build:css"
  end
end

# assets:precompile の前に assets:build を実行
Rake::Task["assets:precompile"].enhance([ "assets:build" ])
