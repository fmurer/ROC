note
	description: "API to manage files."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_FILE_UPLOADER_API

inherit
	CMS_MODULE_API

	REFACTORING_HELPER

create
	make

feature -- Access

	uploads_directory_name: STRING = "uploaded_files"

	uploads_location: PATH
		do
			Result := cms_api.files_location.extended (uploads_directory_name)
		end

	file_link (f: CMS_FILE): CMS_LOCAL_LINK
		local
			s: STRING
		do
			s := "files"
			across
				f.location.components as ic
			loop
				s.append_character ('/')
				s.append (percent_encoded (ic.item.name))
			end
			create Result.make (f.filename, s)
		end

feature -- Factory

	new_file (p: PATH): CMS_FILE
		do
			create Result.make (p, cms_api)
		end

	new_uploads_file (p: PATH): CMS_FILE
			-- New uploaded path from `p' related to `uploads_location'.
		do
			create Result.make ((create {PATH}.make_from_string (uploads_directory_name)).extended_path (p), cms_api)
		end

feature -- Storage

	save_uploaded_file (f: CMS_UPLOADED_FILE)
		local
			p: PATH
			ut: FILE_UTILITIES
			stored: BOOLEAN
		do
			reset_error
			p := f.location
			if p.is_absolute then
			else
				p := uploads_location.extended_path (p)
			end
			if ut.file_path_exists (p) then
					-- FIXME: find an alternative name for it, by appending  "-" + i.out , with i: INTEGER;
				error_handler.add_custom_error (-1, "uploaded file storage failed", "A file with same name already exists!")
			else
					-- move file to path
				stored := f.move_to (p)
				if not stored then
					error_handler.add_custom_error (-1, "uploaded file storage failed", "Issue occurred when saving uploaded file!")
				end
			end
		end

end
