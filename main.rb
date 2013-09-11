require 'nokogiri'
require 'sax-machine'
require 'open-uri'
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
def download(site="http://xkcd.com/1" , comic_number = 1)
	comic = Nokogiri::HTML(open(site))
	comic.xpath("//div[@id='comic']").css('img').map{ |i|
		print "%s\n" % i['src']
		print "%s\n\n" % i['title']
	}

	comic.xpath("//ul[@class='comicNav']").css('a').map{ |i|
		if i['rel'] == "next"
			if i['href'] == '#'
				print 'Finished Download'
				return
			end
			download("http://xkcd.com" << i['href'], comic_number+1)
			return
		end
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

download()


