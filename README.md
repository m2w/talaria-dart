talaria is a commenting system for static content, such as github pages, that uses github commits to identify content and store its comments. You can see talaria in action [here](http://blog.tibidat.com).

# Using talaria

Using talaria requires at least two, at most three, steps:

## Tell talaria to where to find your content

- With a [dart development environment](https://www.dartlang.org/tools/editor/):

	Open the talaria directory with the dart editor (``File -> Open Existing Folder``) and modify ``web/talaria.dart`` so that talaria uses your (_publicly available_) repository.
	
	```dart
	const String REPOSITORY_NAME = '{YOUR_REPOSITORY_NAME}';
	const String GITHUB_USERNAME = '{YOUR_USERNAME}';
	```
	
	Optionally you can customize where talaria locates to your content. Currently talaria is written with a jekyll-based system in mind.
	
	```dart
	const String COMMENTABLE_CONTENT_PATH_PREFIX = '_posts/'; // this MUST be a path **relative** to the root of your repository!
	const String CONTENT_SUFFIX = '.md'; // set this to whatever markup your content is written in
	```
	
	You can now compile the changed dart to javascript, ``Tools -> Pub Build``. After a successful build you will find the updated ``talaria.html_bootstrap.dart.js`` in the ``out`` directory.

- Without dart (using the precompiled javascript):

	Go through the ``out/talaria.html_bootstrap.dart.js`` file that is included in the repository and replace occurances of ``m2w.github.com`` with ``{YOUR_REPOSITORY_NAME}`` and ``m2w`` with ``{YOUR_USERNAME}``.

## Customize the look'n feel of talaria

By default talaria essentially clones the github comment styling. You can modify this to suit your needs by editing the ``<style>`` sections of ``web/talaria-wrapper.html`` and ``web/talaria-safehtml.html``. 
Here's a quick overview of the ``<div>`` layering:

```
wrapper
- header 
- comment-load-error
- comment-count
+ comment-list
| + comment-bubble
\ | + comment-bubble-content
  \ | + comment-bubble-inner
    \ | - comment-header
      \ - comment-content
```

## Add talaria to your site

For the following I am assuming that your site follows the standard jekyll directory structure.

```bash
$ cp web/talaria-wrapper.html /web/talaria-safehtml.html {PATH_TO_YOUR_BLOG}/_includes
$ cp build/talaria.html_bootstrap.dart.js {PATH_TO_YOUR_BLOG}/static/js 
```

Add 

```html
<script src="/static/js/talaria.html_bootstrap.dart.js"></script>
``` 

to the ``<head>`` section of your base template for commentable content.

Add ``{% include talaria-wrapper.html %}`` and ``{% include talaria-safehtml.html %}`` near the top of your base template for commentable content's ``<body>``.

__Alternatively__, you can use ``<link rel="import">`` to load the templates. In this case you might place ``web/talaria-wrapper.html`` and ``/web/talaria-safehtml.html`` into ``{PATH_TO_YOUR_BLOG}/static/components`` and load them from there.
Ensure that the imports are placed __before__ the ``<script>`` loading talaria. 

You can now use 

```html 
<talaria-wrapper permalink="{{PERMALINK_FOR_THIS_POST}}" hide_comments="{{true|false}}"></talaria-wrapper>
``` 

within your templates: 

- ``hide_comments`` (true by default) displays a comment-count for the post, which when clicked expands the comments.
- ``permalink`` drives talaria's content discovery. It is very important that the permalink allow talaria to find the file that contains the content; 
e.g. if the permalink to a post is ``/2013/03/22/blog-relaunch`` talaria expects your content for this post to be located in the file 
``COMMENTABLE_CONTENT_PATH_PREFIX/2013-03-22-blog-relaunchCONTENT_SUFFIX``

# TODOs

There are a couple of things still missing:

-[] Customizable permalink schemes
-[] Improvement of the error handling (this includes edge cases, such as wrong repository names, or invalid permalinks)


# FYI

The github API is currently restricted to **60 API calls per hour** for unauthenticated users. This means that your users can retrieve comments for at most 30 entries. This number is lowered if you have multiple commits per 'content source file'; by 1 additional API request per additional commit (so if you have 3 commits for a the post `/2013/03/22/blog-relaunch`, talaria actually needs a total of 4 API calls to get all comments). talaria tries to use `sessionStorage` to reduce the total number of API calls, but users could potentially still run into `403s` from throtteling, in which case talaria simply states that comments can be viewed directly on github, along with a link to the latest commit for the entry.

Users clicking the "Add comment" buttons get redirected to github, where they can then login and comment. However, at this point I do not know of a way to get users back to your site after the redirect.

# Trivia
talaria are the [winged sandals](http://en.wikipedia.org/wiki/Talaria) worn by Hermes in Greek mythology.
