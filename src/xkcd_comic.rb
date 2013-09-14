class XKCDComic
	attr_reader :id, :title, :file, :alt
	def initialize(id, title, file, alt)
		@id = id;
		@title = title
		@file = file
		@alt = alt
	end
end