require './xkcd_comic_list.rb'

comics = XKCDComicList.new

exit = false
while !exit do 
	print "Menu\n\n"
	print "1  - Update\n"
	print "2  - List All comics\n"
	print "3  - Info From Comic #\n"
	print "4  - Stop Updating \n"
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
			if comic.is_a?(XKCDComic)
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
		if '99' == option
			unselected = false
			exit = true
		end
	end	
end
