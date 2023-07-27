puts "Custom RubyGems plugin: Running post_install hook..."
require_relative '../lib/post_install'

module PostInstallHook
  def post_install(options)
    puts "Custom RubyGems plugin: Running post_install hook..."
    require_relative '../lib/post_install'
    PostInstallScript.run
  end
end

Gem.post_install(&PostInstallHook.method(:post_install))
