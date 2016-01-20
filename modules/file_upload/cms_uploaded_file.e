note
	description: "Summary description for {CMS_UPLOADED_FILE}."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_UPLOADED_FILE

create
	make_with_uploaded_file

feature {NONE} -- Initializaion

	make_with_uploaded_file (a_uploads_location: PATH; uf: WSF_UPLOADED_FILE)
		do
			uploads_location := a_uploads_location
			uploaded_file := uf
			location := a_uploads_location.extended (uf.safe_filename)
		end

feature -- Access

	uploaded_file: WSF_UPLOADED_FILE

	uploads_location: PATH

	filename: STRING_32
			-- File name of Current file.
		local
			p: PATH
		do
			p := location
			if attached p.entry as e then
				Result := e.name
			else
				Result := p.name
			end
		end


	location: PATH
			-- Absolute path, or relative path to the `CMS_API.files_location'.

	owner: detachable CMS_USER
			-- Optional owner.

feature -- Element change

	set_owner (u: detachable CMS_USER)
			-- Set `owner' to `u'.
		do
			owner := u
		end

feature -- Basic operation

	move_to (p: PATH): BOOLEAN
		do
			Result := uploaded_file.move_to (p.name)
		end

end
