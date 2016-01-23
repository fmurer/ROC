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

	metadata_directory_name: STRING = ".metadata"

	uploads_location: PATH
		do
			Result := cms_api.files_location.extended (uploads_directory_name)
		end

	metadata_location: PATH
		do
			Result := uploads_location.extended (metadata_directory_name)
		end

	style_location: PATH
		do
			Result := cms_api.module_location_by_name ("file_uploader").extended ("site/files/css/style_upload.css")
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
			original_name: STRING_32
			counter: INTEGER_32
			finished: BOOLEAN
		do
			reset_error
			create original_name.make_from_string (f.filename)

			p := f.location
			if p.is_absolute then
			else
				p := uploads_location.extended_path (p)
			end

			if ut.file_path_exists (p) then
					-- FIXME: find an alternative name for it, by appending  "-" + i.out , with i: INTEGER;
				from
					counter := 1
				until
					finished
				loop
					if ut.file_path_exists (p) then
						f.set_new_location_with_number (counter)
						p := f.location
						if p.is_absolute then
						else
							p := uploads_location.extended_path (p)
						end
						counter := counter + 1
					else
						finished := true
					end
				end
				stored := f.move_to (p)
--				error_handler.add_custom_error (-1, "uploaded file storage failed", "A file with same name already exists!")
			else
					-- move file to path
				stored := f.move_to (p)

			end

			if not stored then
				error_handler.add_custom_error (-1, "uploaded file storage failed", "Issue occurred when saving uploaded file!")
			end
		end

end
