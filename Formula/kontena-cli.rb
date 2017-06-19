class KontenaCli < Formula
  desc "Command-line client for Kontena container & microservices platform"
  homepage "https://kontena.io/"
  url "https://github.com/kontena/kontena.git", :tag => "v1.3.1"
  version "1.3.1"
  head "https://github.com/kontena/kontena.git"

  bottle :unneeded

  depends_on :ruby => "2.1"

  def install
    ruby_command = which("ruby")
    gem_command = File.join(ruby_command.dirname, "gem")

    # Build the gem from sources and install it
    (buildpath/"cli").cd do
      system gem_command, "build", "--norc", "kontena-cli.gemspec"
      system gem_command,
        "install", Dir["kontena-cli-*.gem"].first,
        "--install-dir", buildpath/"out",
        "--wrappers",
        "--env-shebang",
        "--no-document"
    end

    (bin/"kontena").write(exec_script)

    # No need for the cached *.gem
    rm_rf buildpath/"out/cache"

    libexec.install Dir["out/*"]

    # Write a .ruby-version file to match the current ruby version (for rbenv/rvm users)
    ruby_version = Utils.popen_read(ruby_command, "-e", "print RUBY_VERSION")
    (libexec/"bin/.ruby-version").write(ruby_version)

    zsh_completion.install buildpath/"cli/lib/kontena/scripts/kontena.zsh" => "_kontena"
    bash_completion.install buildpath/"cli/lib/kontena/scripts/kontena.bash" => "kontena"
  end

  def exec_script
    <<-EOS.undent
      #!/bin/sh

      export GEM_HOME=#{libexec}
      export KONTENA_EXTRA_BUILDTAGS=homebrew#{",head" if build.head?}
      exec #{libexec/"bin/kontena"} "$@"
    EOS
  end

  def caveats
    unless Dir["/usr/local/{opt,var}/rbenv/shims/kontena"].empty?
      <<-EOS.undent
        You seem to use rbenv and have a previously installed kontena-cli that
        may get loaded instead of the homebrew installed version.

        To uninstall the previous installation copy and paste this into the
        terminal:

          for ruby in $(rbenv whence kontena); do \\
            rbenv shell $ruby; gem uninstall --force -a -x kontena-cli; \\
          done; \\
          rbenv rehash
      EOS
    end
  end

  test do
    assert_match "+homebrew", shell_output("#{bin}/kontena --version")
    assert_match "login", shell_output("#{bin}/kontena complete kontena master")
  end
end
