---
name: Google News
tags: website
class: borderless
icon: newspaper
href: https://news.google.com
size: 430x640
order: 9
description: Google News mobile site as a widget
clear: >
  body > *:not([role="menu"]), [role="button"], [role="presentation"] > a
remove: >
  [role="tablist"]
css: >
  [role="banner"] {background-color: #00000044 !important; -webkit-backdrop-filter: blur(20px);}
config: |
  {"tabs":[
    {"label": "For You", "image":"person.circle.fill", "url":"https://news.google.com/foryou"},
    {"label": "Top Stories", "image":"globe", "url":"https://news.google.com/topstories"},
    {"label": "Following", "image":"star", "url":"https://news.google.com/my/library"}
  ]}
---
