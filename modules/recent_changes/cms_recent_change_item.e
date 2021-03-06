note
	description: "Information related to change event."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_RECENT_CHANGE_ITEM

inherit
	COMPARABLE

create
	make

feature {NONE} -- Initialization

	make (a_source: READABLE_STRING_8; lnk: CMS_LOCAL_LINK; a_date_time: DATE_TIME)
		do
			source := a_source
			link := lnk
			date := a_date_time
		end

feature -- Access

	link: CMS_LOCAL_LINK
			-- Local link associated with the resource.

	date: DATE_TIME
			-- Time of the event item.

	author_name: detachable READABLE_STRING_32
			-- Optional author name.
			-- It is possible to have author_name /= Void and author = Void.

	author: detachable CMS_USER
			-- Optional author.

	source: READABLE_STRING_8
			-- Source of Current event.

	information: detachable READABLE_STRING_8
			-- Optional information related to Current event.
			--| For instance: creation, trashed, modified, ...

feature -- Element change

	set_author_name (n: like author_name)
			-- Set `author_name' to `n'.
		do
			author_name := n
		end

	set_author (u: like author)
			-- Set `author' to `u'.
		do
			author := u
			if u /= Void and author_name = Void then
				set_author_name (u.name)
			end
		end

	set_information (a_info: like information)
			-- Set `information' to `a_info'.
		do
			information := a_info
		end

feature -- Comparison

	is_less alias "<" (other: like Current): BOOLEAN
			-- <Precursor>
		do
			Result := date < other.date
		end

end
