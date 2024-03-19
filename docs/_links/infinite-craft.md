---
name: Infinite Craft
author: Neal Agarwal
author-link: https://neal.fun/
icon: download
tags: website
href: https://neal.fun/infinite-craft
size: 828x512
minsize: 801x400
ua: mobile
clear: >
  .container, .mobile-sound
css: |
    body,
    .item-emoji,
    .instance-emoji{
        filter:invert()        
    }
    .item,
    .item.instance {
        background:#fff4 !important;
        border-color:transparent !important;
        -webkit-backdrop-filter: invert() blur(10px);
    }
    .sidebar-controls:after {display:none}
    .container {
        background-color:transparent !important;
    }
    div.sidebar {
        background-color:#fff2 !important;
        border-color:transparent !important
    }
    .container {
    --sidebar-bg: #fff5 !important;
    --border-color: #fff2 !important;
    --background-color: #fff0 !important;
    }   
---