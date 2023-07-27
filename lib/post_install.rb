puts "PostInstallScript loaded successfully."

class PostInstallScript
  def self.run
    puts "PostInstallScript.run method executed."
    # Your post-installation script logic here
    # Will read and execute the tasks defined in tasks/tasks_install.rake
    if ENV['SKIP_POST_INSTALL_HOOK'].nil?
      puts "Running post-installation setup..."
      Rake::Task["rake_install:install"].invoke
      puts "Post-installation setup completed."
    end
  end
end

load File.join(File.dirname(__FILE__), 'tasks', 'tasks_install.rake')
