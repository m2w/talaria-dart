talaria is a commenting system for static content, such as github pages, that uses github commits to identify content and store its comments. You can see talaria in action [here](http://blog.tibidat.com).

# Using talaria

the dart rewrite is close to completion, but currently still unstable and in its test phase.
Full documentation will follow shortly.

# FYI

The github API is currently restricted to **60 API calls per hour** for unauthenticated users. This means that your users can retrieve comments for at most 30 entries. This number is lowered if you have multiple commits per 'content source file'; by 1 additional API request per additional commit (so if you have 3 commits for a the post `/2013/03/22/blog-relaunch`, talaria actually needs a total of 4 API calls to get all comments). talaria tries to use `sessionStorage` to reduce the total number of API calls, but users could potentially still run into `403s` from throtteling, in which case talaria simply states that comments can be viewed directly on github, along with a link to the latest commit for the entry.

Users clicking the "Add comment" buttons get redirected to github, where they can then login and comment. However, at this point I do not know of a way to get users back to your site after the redirect.

# Trivia
talaria are the [winged sandals](http://en.wikipedia.org/wiki/Talaria) worn by Hermes in Greek mythology.
