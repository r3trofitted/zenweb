#!/usr/bin/ruby -w

require "rubygems"
require "minitest/autorun"

require "zenweb/site"
require "test/helper"

class Zenweb::Site
  attr_writer :layouts
end

class TestZenwebSite < Minitest::Test
  include ChdirTest("example-site")

  attr_accessor :site

  def setup
    super

    self.site = Zenweb::Site.new
  end

  def test_categories
    site.scan
    cats = site.categories
    assert_equal %w(blog pages projects), cats.keys.sort

    exp = [["blog/2012-01-02-page1.html.md",
            "blog/2012-01-03-page2.html.md",
            "blog/2012-01-04-page3.html.md"],
           ["pages/nonblogpage.html.md"],
           ["projects/zenweb.html.erb"]]

    assert_equal exp, cats.values.map { |a| a.map(&:path).sort }.sort
  end

  def test_categories_method_missing
    site.scan
    cats = site.categories

    exp = ["blog/2012-01-02-page1.html.md",
           "blog/2012-01-03-page2.html.md",
           "blog/2012-01-04-page3.html.md"]

    assert_equal exp, cats.blog.map(&:path).sort

    assert_raises NoMethodError do
      cats.wtf
    end
  end

  def test_fix_subpages
    top = setup_complex_website

    site.fix_subpages
    site.fix_subpages
    # ...

    sp  = site.pages
    exp = [[sp["blog/index.html.md"],
            [[sp["blog/2014-01-01-first.html.md"], []],
             [sp["blog/2014-02-02-second.html.md"], []],
             [sp["blog/2014-03-03-third.html.md"], []]]]]

    assert_equal exp, top.all_subpages
  end

  def test_config
    assert_equal "_config.yml", site.config.path
  end

  def test_configs
    site.scan

    exp = %w[_config.yml blog/_config.yml]

    assert_equal exp, site.configs.keys.sort

    exp = [Zenweb::Config]
    assert_equal exp, site.configs.values.map(&:class).uniq
  end

  def test_generate
    Rake.application = Rake::Application.new
    extend Rake::DSL

    ran = false
    task(:site) do
      ran = true
    end

    site.generate

    assert ran, "Site#generate needs to call the site task"
  end

  def test_html_pages
    Rake.application = Rake::Application.new
    site.scan

    exp = %w[about/index.html.md
             blog/2012-01-02-page1.html.md
             blog/2012-01-03-page2.html.md
             blog/2012-01-04-page3.html.md
             blog/index.html.erb
             index.html.erb
             pages/index.html.erb
             pages/nonblogpage.html.md
             projects/index.html.erb
             projects/zenweb.html.erb]

    assert_equal exp, site.html_pages.map(&:path).sort

    diff = site.pages.values - site.html_pages

    exp = %w[atom.xml.erb css/colors.css.less css/styles.css
             css/syntax.css img/bg.png js/jquery.js js/site.js
             sitemap.xml.erb]

    assert_equal exp, diff.map(&:path).sort
  end

  def test_inspect
    assert_equal "Site[0 pages, 0 configs]", site.inspect

    site.scan

    assert_equal "Site[18 pages, 2 configs]", site.inspect
  end

  def test_layout
    site.scan
    assert_equal "_layouts/post.erb", site.layout("post").path
  end

  def test_method_missing
    assert_equal "Example Website", site.header
  end

  def test_method_missing_missing
    exp = "Site[0 pages, 1 configs] does not define missing\n"

    assert_output "", exp do
      assert_nil site.missing
    end
  end

  def test_method_missing_nil
    site.config.h["nil_key"] = nil

    assert_silent do
      assert_nil site.nil_key
    end
  end

  def test_pages
    site.scan

    excludes = %w[Rakefile config.ru]

    exp = Dir["**/*"].
      select { |p| File.file? p }.
      reject! { |p| p =~ /(^|\/)_/ }.
      sort - excludes

    assert_equal exp, site.pages.keys.sort

    exp = [Zenweb::Page]

    assert_equal exp, site.pages.values.map(&:class).uniq
  end

  def test_pages_by_date
    site.scan

    srand 42
    $dates = {}

    site.html_pages.sort_by(&:title).each do |x|
      $dates[x.path] = rand(100)
    end

    site.pages.values.each do |x|
      def x.date
        $dates[self.path]
      end
    end

    exp = [[-92, "Example Page 1"],
           [-86, "example.com pages"],
           [-82, "example.com"],
           [-74, "example.com projects"],
           [-74, "zenweb"],
           [-71, "Example Page 3"],
           [-60, "Example Website"],
           [-51, "About example.com"],
           [-20, "Some regular page"],
           [-14, "Example Page 2"]]

    assert_equal exp, site.pages_by_date.map { |x| [-x.date.to_i, x.title] }
  end

  def test_pages_by_url
    site.scan

    exp = Hash[site.pages.values.map { |p| [p.url, p] }]
    assert_equal exp, site.pages_by_url
  end

  def test_scan # the rest is tested via the other tests
    assert_empty site.pages
    assert_empty site.configs
    assert_empty site.layouts

    site.scan

    refute_empty site.pages
    refute_empty site.configs
    refute_empty site.layouts
  end

  def test_scan_excludes_underscores
    site.scan

    exp = %w[
           about/index.html.md
           atom.xml.erb
           blog/2012-01-02-page1.html.md
           blog/2012-01-03-page2.html.md
           blog/2012-01-04-page3.html.md
           blog/index.html.erb
           css/colors.css.less
           css/styles.css
           css/syntax.css
           img/bg.png
           index.html.erb
           js/jquery.js
           js/site.js
           pages/index.html.erb
           pages/nonblogpage.html.md
           projects/index.html.erb
           projects/zenweb.html.erb
           sitemap.xml.erb
          ]

    assert_equal exp, site.pages.keys.sort
  end

  def test_wire
    Rake.application = Rake::Application.new
    site.scan
    site.wire

    assert_tasks do
      assert_task "virtual_pages", nil, Rake::Task

      assert_task ".site"
      assert_task ".site/about"
      assert_task ".site/blog"
      assert_task ".site/blog/2012"
      assert_task ".site/blog/2012/01"
      assert_task ".site/blog/2012/01/02"
      assert_task ".site/blog/2012/01/03"
      assert_task ".site/blog/2012/01/04"
      assert_task ".site/css"
      assert_task ".site/img"
      assert_task ".site/js"
      assert_task ".site/pages"
      assert_task ".site/projects"
      assert_task "_config.yml"
      assert_task "extra_wirings", nil, Rake::Task

      # stupid simple deps
      assert_task "_layouts/site.erb",                %w[_config.yml]
      assert_task "atom.xml.erb",                     %w[_config.yml]
      assert_task "blog/_config.yml",                 %w[_config.yml]
      assert_task "css/colors.css.less",              %w[_config.yml]
      assert_task "css/styles.css",                   %w[_config.yml]
      assert_task "css/syntax.css",                   %w[_config.yml]
      assert_task "img/bg.png",                       %w[_config.yml]
      assert_task "js/jquery.js",                     %w[_config.yml]
      assert_task "js/site.js",                       %w[_config.yml]
      assert_task "sitemap.xml.erb",                  %w[_config.yml]

      assert_task ".site/about/index.html",           %w[.site/about           about/index.html.md          ]
      assert_task ".site/atom.xml",                   %w[.site                 atom.xml.erb                 ]
      assert_task ".site/blog/2012/01/02/page1.html", %w[.site/blog/2012/01/02 blog/2012-01-02-page1.html.md]
      assert_task ".site/blog/2012/01/03/page2.html", %w[.site/blog/2012/01/03 blog/2012-01-03-page2.html.md]
      assert_task ".site/blog/2012/01/04/page3.html", %w[.site/blog/2012/01/04 blog/2012-01-04-page3.html.md]
      assert_task ".site/blog/index.html",            %w[.site/blog
                                                         .site/blog/2012/01/02/page1.html
                                                         .site/blog/2012/01/03/page2.html
                                                         .site/blog/2012/01/04/page3.html
                                                         blog/index.html.erb]
      assert_task ".site/css/colors.css",             %w[.site/css             css/colors.css.less          ]
      assert_task ".site/css/styles.css",             %w[.site/css             css/styles.css               ]
      assert_task ".site/css/syntax.css",             %w[.site/css             css/syntax.css               ]
      assert_task ".site/img/bg.png",                 %w[.site/img             img/bg.png                   ]
      assert_task ".site/index.html",                 %w[.site
                                                         .site/about/index.html
                                                         .site/blog/2012/01/02/page1.html
                                                         .site/blog/2012/01/03/page2.html
                                                         .site/blog/2012/01/04/page3.html
                                                         .site/blog/index.html
                                                         .site/pages/index.html
                                                         .site/pages/nonblogpage.html
                                                         .site/projects/index.html
                                                         .site/projects/zenweb.html
                                                         index.html.erb]
      assert_task ".site/js/jquery.js",               %w[.site/js              js/jquery.js                 ]
      assert_task ".site/js/site.js",                 %w[.site/js              js/site.js                   ]
      assert_task ".site/pages/index.html",           %w[.site/pages           .site/pages/nonblogpage.html pages/index.html.erb]
      assert_task ".site/pages/nonblogpage.html",     %w[.site/pages           pages/nonblogpage.html.md    ]
      assert_task ".site/projects/index.html",        %w[.site/projects        .site/projects/zenweb.html projects/index.html.erb]
      assert_task ".site/projects/zenweb.html",       %w[.site/projects        projects/zenweb.html.erb     ]
      assert_task ".site/sitemap.xml",                %w[.site                 sitemap.xml.erb              ]

      assert_task "_layouts/post.erb",                %w[_config.yml      _layouts/site.erb]
      assert_task "_layouts/project.erb",             %w[_config.yml      _layouts/site.erb]
      assert_task "about/index.html.md",              %w[_config.yml      _layouts/site.erb]
      assert_task "blog/2012-01-02-page1.html.md",    %w[_layouts/post.erb blog/_config.yml]
      assert_task "blog/2012-01-03-page2.html.md",    %w[_layouts/post.erb blog/_config.yml]
      assert_task "blog/2012-01-04-page3.html.md",    %w[_layouts/post.erb blog/_config.yml]
      assert_task "blog/index.html.erb",              %w[_layouts/site.erb blog/_config.yml]
      assert_task "index.html.erb",                   %w[_config.yml      _layouts/site.erb]
      assert_task "pages/index.html.erb",             %w[_config.yml      _layouts/site.erb]
      assert_task "pages/nonblogpage.html.md",        %w[_config.yml      _layouts/site.erb]
      assert_task "projects/index.html.erb",          %w[_config.yml      _layouts/site.erb]
      assert_task "projects/zenweb.html.erb",         %w[_config.yml      _layouts/project.erb]

      deps = %w[.site
                .site/about/index.html
                .site/atom.xml
                .site/blog/2012/01/02/page1.html
                .site/blog/2012/01/03/page2.html
                .site/blog/2012/01/04/page3.html
                .site/blog/index.html
                .site/css/colors.css
                .site/css/styles.css
                .site/css/syntax.css
                .site/img/bg.png
                .site/index.html
                .site/js/jquery.js
                .site/js/site.js
                .site/pages/index.html
                .site/pages/nonblogpage.html
                .site/projects/index.html
                .site/projects/zenweb.html
                .site/sitemap.xml]

      assert_task "site", deps, Rake::Task
    end
  end
end
