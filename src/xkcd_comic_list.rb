#
#The MIT License (MIT)
#
#Copyright (c) 2013 Gustavo Lima de Magalhães
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
#the Software, and to permit persons to whom the Software is furnished to do so,
#subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
#COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'forwardable'
require 'nokogiri'
require 'open-uri'
require 'sequel'
require 'timeout'
require './xkcd_comic'

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
		
		@update_thread = nil
	end
	
	def update
		#if a thread is alredy running don't start a new one
		if @update_thread != nil && @update_thread.alive?
			@update_thread.run
			return
		end
		#verifies if it's the first time running
		if (@comics.max(:id) == nil)
			#Start a thread to update comics
			@update_thread = Thread.new do
				next_comic = "http://xkcd.com/1/"
				begin
					next_comic = download(next_comic)
				end while next_comic != ""
				print "Finished Updating Comics!\n"
				clean_thread
			end
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
						@update_thread = Thread.new do
							next_comic = "http://xkcd.com" << i['href']
							begin
								next_comic = download(next_comic)
							end while next_comic != ""
							clean_thread
						end
					else
						print "Finished Updating Comics!\n"
					end
					return
				end
			}
		end
	end
	
	def stop_update
		if @update_thread != nil && @update_thread.alive?
			Thread.kill(@update_thread)
			clean_thread
		else
			return
		end
	end

	#TODO: Add throw when value is out of bounds
	def [](i)
		@comics.where(:id => i).map{  |comic| 
			return XKCDComic.new(comic[:id] , comic[:title] , "./xkcd_comics/" << comic[:file] , comic[:alt])
		}	
		return nil
	end
	
	#enumerable methods
	#iterates through each mebmer of the database
	def each
		@comics.each{  |comic| 
			yield XKCDComic.new(comic[:id] , comic[:title] , "./xkcd_comics/" << comic[:file] , comic[:alt])
		}	
	end
	
#	def each_with_index
#	end
#	
	def first
		return self[1]
	end
	
	
	private

	#clean 
	def clean_thread
		@update_thread = nil
	end
	
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