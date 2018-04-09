ProjectName = "rpgxp"
DefaultPrefix = "/usr/local"

Languages = %w(es)
SrcFiles = Dir["src/*.rb"]
GladeFiles = Dir["data/ui/*.glade"]

task :default do
  FileUtils.mkdir_p("data/system")

  do_fatal_checks
  check_file_ask_readme("data/system/GMGSx.sf2", false)

  Rake::Task[:mo].invoke
  Rake::Task[:executable].invoke
end

def do_fatal_checks
  check_file_ask_readme("data/system/mkxp_linux", true)
end

task :deps do
  gem_install("gtk3")
  gem_install("ruby-filemagic", "filemagic")
  gem_install("launchy")
  gem_install("os")
  gem_install("gettext")
  gem_install("open5", "open3")
end

task :clean do
  # locale has a slash to tell the user that it was a directory
  sh "rm -rf #{executable} locale/"
end

task :install do
  do_fatal_checks
  # install binary
  sh "install #{executable} #{bindir}"
  # install ruby files in lib/
  sh "mkdir -p #{srcdir}"
  for src in SrcFiles
    sh "install -c #{src} #{srcdir}"
  end
  # install glade files
  sh "mkdir -p #{datadir}/ui"
  for file in GladeFiles
    sh "install -c -m 644 #{file} #{datadir}/ui"
  end
  # copy system files
  sh "cp -r data/system #{datadir}"
  # install desktop
  sh "mkdir -p #{prefix}/share/applications"
  sh "install -c -m 644 data/rpgxp.desktop #{prefix}/share/applications"
  # install locale
  for lang in Languages
    msgdir = "#{localedir}/#{lang}/LC_MESSAGES"
    sh "mkdir -p #{msgdir}"
    sh "install -c -m 644 #{mo_file(lang)} #{msgdir}"
  end
end

task :executable do
  code = "#!/usr/bin/env ruby\n"
  code += "$PROJECT_NAME = '#{executable}'\n"
  code += "$LOCALE_DIR = '#{localedir}'\n"
  code += "$DATA_DIR = '#{datadir}'\n"
  code += "load '#{srcdir}/run.rb'\n"
  IO.write(executable, code)
  sh "chmod +x #{executable}"
end

task :pot do
  files = GladeFiles
  sh "mkdir -p po"
  sh "xgettext #{files.join(" ")} -o #{pot_file}"
  for lang in Languages
    sh "msgmerge -U #{po_file(lang)} #{pot_file}"
  end
end

task :mo do
  sh "mkdir -p locale"
  for lang in Languages
    msgdir = "locale/#{lang}/LC_MESSAGES"
    sh "mkdir -p #{msgdir}"
    sh "msgfmt #{po_file(lang)} -o #{msgdir}/#{ProjectName}.mo"
  end
end

def executable
  ProjectName
end

def prefix
  ENV["PREFIX"] || DefaultPrefix
end

def bindir
  "#{prefix}/bin"
end

def srcdir
  "#{prefix}/lib/#{ProjectName}"
end

def datadir
  "#{prefix}/share/#{ProjectName}"
end

def localedir
  "#{prefix}/share/locale"
end

def mo_file(lang)
  "locale/#{lang}/LC_MESSAGES/#{ProjectName}.mo"
end

def po_file(lang)
  "po/#{lang}.po"
end

def pot_file
  "po/#{ProjectName}.pot"
end

def has_require?(name)
  printf("Checking whether '#{name}' exists... ")
  require(name)
  puts("Yes")
  return true
rescue LoadError
  puts("No")
  return false
end

def gem_install(gem, name = nil)
  name = gem unless name
  Gem.install(gem) unless has_require?(name)
end

def check_file_ask_readme(file, fatal = true)
  if File.exists?(file)
    true
  else
    dir = File.dirname(file)
    name = File.basename(file)
    severity = fatal ? "ERROR" : "WARNING"
    STDERR.puts("#{severity}: There is no #{name} in #{dir}. Read README.md")
    if fatal
      exit!(1)
    end
    false
  end
end

