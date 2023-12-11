Gem::Specification.new do |s|
  s.name        = "zenweb"
  s.version     = "3.11.0"
  s.summary     = "A set of classes/tools for organizing and formating a website."
  s.description = <<~TXT
    Zenweb is a set of classes/tools for organizing and formating a website. It is website oriented rather than webpage oriented, unlike most rendering tools. It is content oriented, rather than style oriented, unlike most rendering tools. It uses a rubygems plugin system to provide a very flexible, and powerful system.
    
    Zenweb 3 was inspired by jekyll. The filesystem layout is similar to jekyll’s layout, but zenweb isn’t focused on blogs. It can do any sort of website just fine.
    
    Zenweb uses rake to handle dependencies. As a result, scanning a website and regenerating incrementally is not just possible, it is blazingly fast.
  TXT
  s.authors     = ["Ryan Davis"]
  s.email       = "ryand-ruby@zenspider.com"
  s.homepage    = "https:/github.com/seattlerb/zenweb"
  s.license     = "MIT"
  
  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  
  s.add_dependency "rake",             [">= 0.9", "< 15"]
  s.add_dependency "makerakeworkwell", "~> 1.0"
  s.add_dependency "less",             "~> 2.0"
  s.add_dependency "coderay",          "~> 1.0"
  s.add_dependency "kramdown",         "~> 2.0"
  s.add_dependency "kramdown-syntax-coderay", "~> 1.0"
  s.add_dependency "kramdown-parser-gfm", "~> 1.0"
end
