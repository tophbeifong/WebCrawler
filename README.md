# WebCrawler
Ruby &amp; MySQL Web URL Crawler. 

Extracts url's from the <a href="" tag's using Regex.
#### Remember to edit the initialize method with your MySQL logins...

Database Structure:
create database webcrawler;
create table listings (url VARCHAR(255), description TEXT(400), keywords TEXT(500));
