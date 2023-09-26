#!/bin/sh
BUILD=/E/tic80-v1.1-win/tic80 
CART=pyramid
ITCH_USER=thegrumpygamedev
ITCH_PROJECT=pyramid-of-ahraxis

rm -rf ./pub-linux
mkdir ./pub-linux
$BUILD --cli --fs=. --cmd "load $CART.tic & export linux ./pub-linux/$CART & exit" 
butler push pub-linux $ITCH_USER/$ITCH_PROJECT:linux

rm -rf ./pub-windows
mkdir ./pub-windows
$BUILD --cli --fs=. --cmd "load $CART.tic & export win ./pub-windows/$CART & exit" 
butler push pub-windows $ITCH_USER/$ITCH_PROJECT:windows

rm -rf ./pub-mac
mkdir ./pub-mac
$BUILD --cli --fs=. --cmd "load $CART.tic & export mac ./pub-mac/$CART & exit" 
butler push pub-mac $ITCH_USER/$ITCH_PROJECT:mac

rm -rf ./pub-html
mkdir ./pub-html
$BUILD --cli --fs=. --cmd "load $CART.tic & export html ./pub-html/$CART.zip & exit" 
butler push pub-html/$CART.zip $ITCH_USER/$ITCH_PROJECT:html

git add -A
git commit -m "shipped it!"