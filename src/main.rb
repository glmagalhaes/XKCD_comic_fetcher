require 'nokogiri'
require 'open-uri'
require 'sequel'
require 'timeout'

#this will be the code to download all the old comics
#it returns the next comic url if available
def download(site)
	begin
		Timeout::timeout(60){	
			src_comic = ''
			alt_text = ''
			
			#Download the web Page
			comic = Nokogiri::HTML(open(site))
			
			#Get the comic Title
			title = comic.xpath("//div[@id='ctitle']").text
			
			#Download the comic itself
			comic.xpath("//div[@id='comic']").css('img').map{ |i|
				open('./xkcd_comics/'<< File.basename(i['src']), 'wb') do |file|
					file << open(i['src']).read
				end
				#get the filename of the comic
				src_comic =  File.basename(i['src'])
				#get the alt-text of the comic
				alt_text =  i['title']
			}
			
			#Get the comic unique id
			comic_id = URI(site).path.split('/').join.to_i

			#Insert the comic in the database
			$comics.insert(:id => comic_id , :title => title, :file => src_comic, :alt => alt_text)
			print "Downloaded comic #%s \n" % comic_id

			comic.xpath("//ul[@class='comicNav']").css('a').map{ |i|
				if i['rel'] == "next"
					if i['href'] == '#'
						print 'Finished Download'
						return ''
					else
						return 'http://xkcd.com' << i['href']
					end
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
	if ($comics.max(:id) == nil)
		next_comic = "http://xkcd.com/1/"
		begin
			next_comic = download(next_comic)
		end while next_comic != ""
		print "Finished Updating Comics!\n"
	else
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
				if !(i['href'] == '#')
					next_comic = "http://xkcd.com" << i['href']
					begin
						next_comic = download(next_comic)
					end while next_comic != ""
				else
					print "Finished Updating Comics!\n"
				end
				return
			end
		}
	end
end

def info(id)
	$comics.where(:id => id.to_i).each{  |comic| 
		print "id - %s\n" % comic[:id]
		print "title - %s\n" % comic[:title]
		print "file - %s\n" % comic[:file]
		print "alt - %s\n" % comic[:alt]
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
	print "1  - Update\n"
	print "3  - Info From Comic #\n"
	print "99 - Quit\n\n"
	unselected = true
	while unselected do
		print "= "
		option = gets.chomp
		if '1' == option
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
