require 'nokogiri'
require 'sax-machine'
require 'open-uri'
require 'sequel'
require 'timeout'

class AtomEntry
	include SAXMachine
	element :title
	# the :as argument makes this available through atom_entry.author instead of .name
	element :name, :as => :author
	element "feedburner:origLink", :as => :url
	element :summary
	element :content
	element :published
end

# Class for parsing Atom feeds
class Atom
	include SAXMachine
	element :title
	# the :with argument means that you only match a link tag that has an attribute of :type => "text/html"
	# the :value argument means that instead of setting the value to the text between the tag,
	# it sets it to the attribute value of :href
	element :link, :value => :href, :as => :url, :with => {:type => "text/html"}
	element :link, :value => :href, :as => :feed_url, :with => {:type => "application/atom+xml"}
	elements :entry, :as => :entries, :class => AtomEntry
end

#this will be the code to download all the old comics
#it returns the next comic url if available
def download(site="http://xkcd.com/1")
	src_comic = ''
	alt_text = ''
	begin
		Timeout::timeout(60){	
			comic = Nokogiri::HTML(open(site))
			title = comic.xpath("//div[@id='ctitle']").text
			comic.xpath("//div[@id='comic']").css('img').map{ |i|
				open('./xkcd_comics/'<<File.basename(i['src']), 'wb') do |file|
					file << open(i['src']).read
				end
				src_comic =  i['src']
				alt_text =  i['title']
			}

			comic.xpath("//ul[@class='comicNav']").css('a').map{ |i|
				if i['rel'] == "next"
					if i['href'] == '#'
						print 'Finished Download'
						return ''
					end

					$comics.insert(:id => i['href'].split('/').join.to_i , :title => title, :file => src_comic, :alt => alt_text)
					print "Downloaded comic #%s \n" % i['href'].split('/').join
					return 'http://xkcd.com' << i['href']

				end
			}
		}
	rescue Timeout::Error
		print "Error Downloading comic #%s \n" % i['href'].split('/').join
		retry
	end
end

#Finds Last downloaded comic and continue from there until it's over
def update()
	comic = ''
	begin
		Timeout::timeout(5){	
			comic = Nokogiri::HTML(open('http://xkcd.com/' << $comics.max(:id).to_s << '/' ))
		}
	rescue Timeout::Error
		print  "Error Downloading comic #%s \n" % $comics.max(:id)
		sleep 0.42 and retry
	end
	comic.xpath("//ul[@class='comicNav']").css('a').map{ |i|
		if i['rel'] == "next"
				next_comic = "http://xkcd.com" << i['href']
				begin
					next_comic = download(next_comic)
				end while next_comic != ""
			return
		end
	}
end

def info(id)
	$comics.where(:id => id.to_i).each{  |comic| 
		print "id - %s\n" % comic[:id]
		print "title - %s\n" % comic[:title]
		print "file - %s\n" % comic[:file]
		print "alt - %s\n" % comic[:alt]
	}
end

#this will be the code to keep downloading new comics
feed = Atom.parse(open("http://xkcd.com/atom.xml"))
feed.entries.each do |entry|
	print "%s\n" % entry.title
	Nokogiri::HTML(entry.summary).css('img').map{ |i| 
		print "%s\n" % i['src']
		print "%s\n\n" % i['alt']
	}
end

#comic DB
#connect to database
DB = Sequel.connect('sqlite://comics.db')

#id title file alt
DB.create_table? :xkcd_comics do
  primary_key :id
  String :title
  String :file
  String :alt
end

$comics = DB[:xkcd_comics]

if !Dir.exists?('xkcd_comics')
	Dir.mkdir('xkcd_comics')
end

exit = false
while !exit do 
	print "Menu\n\n"
	print "1  - Firts Time\n"
	print "2  - Update\n"
	print "3  - Info From Comic #\n"
	print "99 - Quit\n\n"
	unselected = true
	while unselected do
		print "= "
		option = gets.chomp
		if '1' == option
			unselected = false
			next_comic = "http://xkcd.com/1"
			begin
				next_comic = download(next_comic)
			end while next_comic != ""
		end
		if '2' == option
			unselected = false
			update()
		end
		if '3' == option
			unselected = false
			print "Comic ID: "
			info(option = gets.chomp)
		end
		if '99' == option
			unselected = false
			exit = true
		end
	end	
end
