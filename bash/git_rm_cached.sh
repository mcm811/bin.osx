#!/bin/sh

echo git rm --cached -r .navigation/ .idea/
echo git commit -m \"remove a directory\"
echo git push origin master
