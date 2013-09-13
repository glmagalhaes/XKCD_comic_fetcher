require 'forwardable'
require 'nokogiri'
require 'open-uri'
require 'sequel'
require 'timeout'

class XKCDComicList
	include Enumerable
	
	def initialize
		#connect to database
		db = Sequel.connect('sqlite://comics.db')

		#create table if it does't exist yet
		#id title file alt
		db.create_table? :xkcd_comics do
		  primary_key :id
		  String :title
		  String :file
		  String :alt
		end

		@comics = db[:xkcd_comics]

		#Create folder for comics if it dosen't exist yet
		if !Dir.exists?('xkcd_comics')
			Dir.mkdir('xkcd_comics')
		end
	end
	
	def update
		if (@comics.max(:id) == nil)
			next_comic = "http://xkcd.com/1/"
			begin
				next_comic = download(next_comic)
			end while next_comic != ""
			print "Finished Updating Comics!\n"
		else
			comic = ''
			begin
				Timeout::timeout(5){	
					comic = Nokogiri::HTML(open('http://xkcd.com/' << @comics.max(:id).to_s << '/' ))
				}
			rescue Timeout::Error
				print  "Error Downloading comic #%s \n" % @comics.max(:id)
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
	
#	def stop_update
#	end

	#TODO: Add throw when value is out of bounds
	def [](i)
		begin
			@comics.where(:id => i).map{  |comic| 
				i = Hash.new
				i['id'] = comic[:id]
				i['title'] =  comic[:title]
				i['file'] = "./xkcd_comics/" << comic[:file]
				i['alt'] =comic[:alt]
				return i
			}	
		rescue
			print 'Out of bounds\n'
				return nil
		end
	end
	
	#enumerable methods
	#iterates through each mebmer of the database
	def each
		@comics.each{  |comic| 
			i = Hash.new
			i['id'] = comic[:id]
			i['title'] =  comic[:title]
			i['file'] = "./xkcd_comics/" << comic[:file]
			i['alt'] =comic[:alt]
			yield i 
		}	
	end
	
#	def each_with_index
#	end
#	
#	def first
#	end
	
	
	private
	
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
				@comics.insert(:id => comic_id , :title => title, :file => src_comic, :alt => alt_text)
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
end