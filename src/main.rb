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

require './XKCDComicList.rb'
#require './reader_window'

include Java


class Main
	def main
		#ReaderWindow.new
		comics = XKCDComicList.new


		exit = false
		while !exit do 
			print "Menu\n\n"
			print "1  - Update\n"
			print "2  - List All comics\n"
			print "3  - Info From Comic #\n"
			print "4  - Stop Updating \n"
			print "5  - Firts Comic\n"
			print "99 - Quit\n\n"
			unselected = true
			while unselected do
				print "= "
				option = gets.chomp
				if '1' == option
					unselected = false
					comics.update()
				end
				if '2' == option
					unselected = false
					print "Comics:\n "
					comics.each { |comic|
						print "---=====---\n"
						print "id - %s\n" % comic.id
						print "title - %s\n" % comic.title
						print "file - %s\n" % comic.file
						print "alt - %s\n" % comic.alt
					}
				end
				if '3' == option
					unselected = false
					print "Comic ID: "
					comic = comics[gets.chomp.to_i]
					if comic != nil
						print "id - %s\n" % comic.id
						print "title - %s\n" % comic.title
						print "file - %s\n" % comic.file
						print "alt - %s\n" % comic.alt
					end
				end
				if '4' == option
					unselected = false
					comics.stop_update
				end
				if '5' == option
					unselected = false
					comic = comics.first
					if comic != nil
						print "id - %s\n" % comic.id
						print "title - %s\n" % comic.title
						print "file - %s\n" % comic.file
						print "alt - %s\n" % comic.alt
					end
				end
				if '99' == option
					unselected = false
					comics.stop_update
					exit = true
				end
			end	
		end
	end
end

Main.new.main
