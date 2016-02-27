/*
  - SQL `WebCrawler` - Ruby/SQL web url crawler.
  - Written by Toph
*/

CREATE DATABASE `webcrawler`;
CREATE TABLE `listings` (url VARCHAR(255), description TEXT(400), keywords TEXT(500));
