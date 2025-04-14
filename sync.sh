synchome=/root/hexo/blog/source/
rsync -av --delete 10.5.0.113:$synchome source/
hexo clean && hexo g

