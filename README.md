# Roland

Roland is a blog-aware, static website generator written in Swift that compiles its templates using PHP and [CommonMark](https://commonmark.org). If you've ever used [Jekyll](https://jekyllrb.com) to build a website, you'll feel right at home with Roland, as Jekyll was the primary source of inspiration.

You can learn more about the motivation for building Roland and see a live website built with it by reading [the introductory blog post](https://tyler.io/roland-static-website-generator-swift/). You can also view [the raw source files for that website here](https://github.com/tylerhall/Roland-sample-website).

## Building with Xcode

Roland has only been tested on macOS 10.14 Mojave and 10.15 Catalina. Although I don't know of any reason why it wouldn't work on other modern versions of macOS as well.

I also have it on my todo list to add Linux support as well. I've never done any Swift development on Linux, so I have no idea what might be involved. Help in this regard would be greatly appreciated.

If you have Xcode 11 installed, compiling `roland` should just be a matter of building the project and then copying the binary to somewhere you can execute it.

The only two 3rd party dependencies are

* [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
* [Down](https://github.com/iwasrobbed/Down) - a Swift wrapper around [CommonMark](https://commonmark.org)

Both libraries are included using the [Swift Package Manager](https://github.com/apple/swift-package-manager) and should be (in theory) automatically imported for you by Xcode. There's no Cocoapods, Carthage, or anything else to manually configure.

## Running Roland

If you execute

	roland

inside a Roland project directory, the settings in `config.plist` will be used to build your website in its entirety and the output placed inside the `_www` directory, which will be created if it does not exist.

You can build using a different property list (for example, to separate development versus production settings) with the `--config` option. And you can choose an alternate destination directory with the `--output` option. As an example:

	roland --config production.plist --output ~/src/prod-build/

Building an entire website will take time. For [my blog](https://tyler.io) with over 200 posts, 30+ categories, and a smattering of other pages, a full build takes about 35 seconds on a MacBook Pro. Definitely nowhere near as fast as [Hugo](https://gohugo.io) compilation times, but there's certainly room for improvement in the code to speed things up.

That said, you can do quick builds by choosing a specific section to compile. For example:

	roland --pages

will only build your static pages, which are typically much faster. Section build flags may be combined together as in:

	roland --posts -rss

This will only build your posts and RSS feed. If no build flags are provided, your entire site will be generated.

There are a few other command line options described via

	roland --help

	USAGE: roland [--config <file>] [--output <directory>] [--posts] [--pages] [--home] [--dates] [--categories] [--rss] [--no-public] [--no-clean]
	
	OPTIONS:
	  -c, --config <file>     The build configuration .plist to use.
	        If omitted, "config.plist" in the current directory will be used.
	  -o, --output <directory>
	                          The build output directory.
	        If omitted, "_www" in the current directory will be used.
	        If the output directory does not exist, it will be created.
	  --posts                 Only build posts.
	  --pages                 Only build pages.
	  --home                  Only build home archives.
	  --dates                 Only build date archives.
	  --categories            Only build category archives.
	  --rss                   Only build RSS feed.
	  --no-public             Don't copy "_public" directory.
	        If set, the contents of the "_public" directory will not be copied into the output directory.
	  --no-clean              Don't clean the output directory.
	        If set, the contents of the outpupt directory will not be deleted prior to building.
	  -h, --help              Show help information.

## Website Structure

In its current form, Roland is designed to output your website in a traditional blog structure. That is, a reverse-chronological listing of posts that can be paged back and forward. Plus, dedicated archive pages that sort posts by date and into categories. Static, one-off pages  are supported as well.

`roland` expects the source files for your website to adhere to the following structure:

	/_pages
		some-page.md
		another-page.md
	/_posts
		a-great-blog-post.md
		yet-another-post.md
		still-one-more.md
	/_public
		some-file.png
		css/
			style.css
		js/
			script.js
	/_templates
		category.php
		date.php
		functions.inc.php
		home.php
		page.php
		post.php
		rss.php
	categories.txt
	config.plist

The files in the above listing are mostly just examples. The only requirements that Roland expects you to adhere to are:

* `_pages` contains static pages that you'd like compiled using your HTML templates (theme).
* `_posts` contains blog posts that will be ordered by date on your website.
* `_public` files will be copied verbatim into your output directory. It's a good place for static assets and anything else you want to include but don't want processed by the Markdown compiler.
* `_templates` contains your HTML (PHP) templates that will be used to render your website.
* `categories.txt` allows you to define a hierarchical structure of post categories.
* `config.plist` is an Apple property list file that defines global settings for your website.

Post and Pages should be written in Markdown following the [CommonMark](https://commonmark.org) spec. They will be compiled using CommonMark's `unsafe` flag, which allows for embedding raw HTML within your markdown.

## Templates

Your templates will be executed using PHP just like any normal PHP script would be. That means you're free to `include()` other PHP or HTML files and use the wealth of functions available in the PHP standard library. You can also import your own PHP helper libraries if you'd like.

Information about your website, posts, pages, and categories will be inserted into PHP's global scope as appropriate so you can use that information within your templates.

For example, the template to render a Post might look like this:

	<?PHP include('inc/header.php'); ?>
	<article>
	  <header>
	    <h1><?PHP echo $post_title; ?></h1>
	    <p><a href="<?PHP echo $post_permalink; ?>"><?PHP echo dater($post_date, 'F j, Y'); ?></a></p>
	  </header>
	  <div>
	    <?PHP echo render($post_content); ?>
	  </div>
	  <?PHP include('inc/post-categories-list.php'); ?>
	  <nav>
	    <div>
	      <?PHP if(isset($post_previous_post_id)) : ?>
	        <?PHP $p = $site_Posts[$post_previous_post_id]; ?>
	        <a class="previous-post" href="<?PHP echo $p['permalink']; ?>"><?PHP echo $p['title']; ?></a>
	      <?PHP endif; ?>
	      <?PHP if(isset($post_next_post_id)) : ?>
	        <?PHP $p = $site_Posts[$post_next_post_id]; ?>
	        <a class="next-post" href="<?PHP echo $p['permalink']; ?>"><?PHP echo $p['title']; ?></a>
	      <?PHP endif; ?>
	    </div>
	  </nav>
	</article>
	</main>
	<?PHP include('inc/footer.php'); ?>

All of the meta data associated with the post will be [`extract()`](https://www.php.net/extract)ed and prefixed with `post_` and made available to you. This includes post properties such as:

* `$post_title`
* `$post_permalink`
* `$post_content`
* `$post_next_post_id`

as well as any custom properties you define.

Similar properties are made available as `$page_XXXXX` for Pages and `$site_XXXXX` for global website settings.

There are also two arrays available for categories:

* `$site_categories_by_name` : an associative array you can lookup categories by name with.
* `$site_categories` : a multi-dimensional array you can traverse to retrieve categories and their children.

Take a look at the [sample templates](https://github.com/tylerhall/Roland-sample-website/tree/master/_templates) included in the [demo website project](https://github.com/tylerhall/Roland-sample-website). They provide a good example of the logic required to recreate a typical WordPress-like blog structure.

## Feedback, Suggestions, Bug Reports, Pull Requests, and all that good stuff...

...is very much encouraged and appreciated. Feel free to open issues in this repo or [contact me directly](https://tyler.io/about/).
