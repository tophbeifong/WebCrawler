require 'mechanize'

class WebCrawler
  def initialize(file)
    #connect to the database when creating the instance
    @file = file
  end

  private
  def save_site_crawl(site_url)
    #begin so it will keep running even if an error occurs
    begin
      if check(site_url)
        File.open(@file,"a") do |data|
          data.puts site_url
        end
      end
      #avoid the code from cancling, display error
    rescue StandardError => error_message
      puts "ERROR: #{error_message}"
    end
  end

  def check(url)
    data = File.read(@file)
    urls = data.split

    if urls.include? url
      return false
    else
      return true
    end
  end

  def fetch_database_urls
    #fetch all urls from the database to scan...

    active_urls = File.read(@file)
    urls = active_urls.split

    return urls
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
        puts url_to_crawl
        #use Mechanize get method to get the page source
        page = agent.get(url_to_crawl)

        #use Mechanize links method to extract the a href links and store in an array
        links =  page.links

        #iterate through the link array to access each element
        links.each do |link|

          #get the value of the HTML link href attribute using "attributes" method
          scraped_url = link.attributes['href']

          #if the url is "#" go onto the next loop item
          next if scraped_url == "#"

          #check if the scrapped url has the protocol on it already
          case scraped_url[0..4]
            when "https" then
              save_site_crawl(scraped_url)
              puts "Checking: #{scraped_url}\n---------------------------------------------\n"
            when "http:" then
              save_site_crawl(scraped_url)
              puts "Checking: #{scraped_url}\n---------------------------------------------\n"
            when "ftp:/" then
              save_site_crawl(scraped_url)
              puts "Checking: #{scraped_url}\n---------------------------------------------\n"
            else

              #split the scraped url to remove the "file" and just grab the domain
              url_split = url_to_crawl.split("/")

              #check if the scrapped url's first character is /
              if scraped_url[0] == "/"

                #if so we'll just append the link
                final_url = url_split[0] + "//" + url_split[2] + scraped_url
              else

                #else we'll add the trailing slash before the file
                final_url = url_split[0] + "//" + url_split[2] + "/" + scraped_url
              end
              puts "Checking: #{final_url}\n---------------------------------------------\n"
              save_site_crawl(final_url)
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

crawler = WebCrawler.new("./urls.txt")
crawler.crawl
