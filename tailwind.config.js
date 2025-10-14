// tailwind.config.js
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/assets/stylesheets/**/*.css"
  ],
  theme: {
    extend: {},
  },
  safelist: [
    // 本番で削除されないように保護するクラス
    'w-10', 'h-10', 'rounded-full',
    'text-[10px]', 'text-[11px]', 'text-base', 'text-sm', 'text-lg',
  ],
  plugins: [],
}
