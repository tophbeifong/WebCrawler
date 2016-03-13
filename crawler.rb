require 'mechanize'
require 'mysql'

class WebCrawler
  def initialize
    #connect to the database when creating the instance
    @connection = Mysql.new("localhost","root","","webcrawler")
  end

  private
  def check_data(site_data)
    #check if the data is already in the database
    row_count = @connection.query("SELECT `url` FROM `listings` WHERE `url`='#{site_data}'")

    #simple if statement to return true if the url is already in the database
    if row_count.num_rows > 0
      return true
    else
      return false
    end
  end

  def save_site_crawl(site_data, title)

    #sanitize single quote for safe SQL query, removes ' characters and replaces them with HTML value
    site_data = site_data.gsub("'","&#39;")
    title = title.gsub("'","&#39;")

    #begin so it will keep running even if an error occurs
    begin
      #if the listing exists it will simply update the query
      if check_data(site_data)
        update_query = @connection.query("UPDATE `listings` SET `url`='#{site_data}',`title`='#{title}' WHERE `url`='#{site_data}'")
      else
        insert_query = @connection.query("INSERT INTO `listings` (`url`,`title`) VALUES ('#{site_data}','#{title}')")
      end
      #avoid the code from cancling, display error
    rescue StandardError => error_message
      puts "ERROR: #{error_message}"
    end
  end

  def fetch_database_urls
    #fetch all urls from the database to scan...
    active_urls = []
    fetch_urls = @connection.query("SELECT `url` FROM `listings`")

    #loop through each result and push to an array so we can return it
    while url = fetch_urls.fetch_row do
      active_urls.push(url)
    end
    return active_urls
  end

  public
  def crawl()
    links_found = 0

    #create Mechanize instance
    agent = Mechanize.new

    #call out fetch method
    database_urls = fetch_database_urls()

    #iterate through the fetched urls and scan
    database_urls.each do |url_to_crawl|
      begin

        #use Mechanize get method to get the page source
        page = agent.get(url_to_crawl[0])

        #use Mechanize links method to extract the a href links and store in an array
        links =  page.links

        #iterate through the link array to access each element
        links.each do |link|

          #get the value of the HTML link href attribute using "attributes" method
          scraped_url = link.attributes['href']

          #if the url is "#" go onto the next loop item
          next if scraped_url == "#"

          #get the page title of the scrapped url
          get_title = agent.get(scraped_url)

          #grab the title of the scrapped page
          page_title = get_title.title

          #check if the scrapped url has the protocol on it already
          case scraped_url[0..4]
            when "https" then
              save_site_crawl(scraped_url, page_title)
              puts "Checking: #{scraped_url}\nTitle: #{page_title}\n---------------------------------------------\n"
            when "http:" then
              save_site_crawl(scraped_url, page_title)
              puts "Checking: #{scraped_url}\nTitle: #{page_title}\n---------------------------------------------\n"
            when "ftp:/" then
              save_site_crawl(scraped_url, page_title)
              puts "Checking: #{scraped_url}\nTitle: #{page_title}\n---------------------------------------------\n"
            else

              #split the scraped url to remove the "file" and just grab the domain
              url_split = url_to_crawl[0].split("/")

              #check if the scrapped url's first character is /
              if scraped_url[0] == "/"

                #if so we'll just append the link
                final_url = url_split[0] + "//" + url_split[2] + scraped_url
              else

                #else we'll add the trailing slash before the file
                final_url = url_split[0] + "//" + url_split[2] + "/" + scraped_url
              end
              puts "Checking: #{final_url}\nTitle: #{page_title}\n---------------------------------------------\n"
              save_site_crawl(final_url, page_title)
          end

          #increment the links found variable
          links_found += 1
        end

        #control errors so script doesnt die.
      rescue StandardError => get_error
        puts "Request Level Error: #{get_error}"
      end
    end
    puts "Status Update:#{links_found} links found."
  end
end

crawler = WebCrawler.new
crawler.crawl
