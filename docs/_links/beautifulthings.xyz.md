---
name: Beautiful Things
tags: website all
icon: download 
symbol: ipod
href: https://beautifulthings.xyz
size: 400x600
class: cover
description: Beautiful things for spatial computing
clear: >
  #main > div
css: |
  * {color: white !important;} 
  [data-framer-name="Active"] {background-color:black !important;}
  [data-framer-name="Logo"] { filter:invert() } 
config: |
  {"tabs":[
    {"label": "All", "image":"asterisk", "url":"/"},
    {"label": "New", "image":"star", "url":"/category/new"},
    {"label": "Culture", "image":"trophy", "url":"/category/culture"},
    {"label": "Tech", "image":"ipod", "url":"/category/tech"},
    {"label": "Nature", "image":"leaf", "url":"/category/nature"},
    {"label": "Other", "image":"ellipsis", "url":"/category/other"},
    {"label": "Create", "image":"wand.and.stars", "url":"https://create.beautifulthings.xyz"}
  ]}
---