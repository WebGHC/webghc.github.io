<a href="/">&lt;home</a>
## Welcome!

This is the project blog for [WebGHC](https://github.com/WebGHC). Here you'll find easy-to-follow documentation on what this project is, why we think it's important, and how we're overcoming obstacles along the way. In fact, the goal of this blog is to provide something useful and understandable for people who are new to the Haskell ecosystem while still being valuable to those with more experience.

### Posts
{% for post in site.posts reversed%}
 * [{{ post.title }}]({{ post.url | prepend: site.baseurl }} )
{% endfor %}
