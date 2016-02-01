note
	description: "file_upload application root class"
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_FILE_UPLOADER_MODULE

inherit
	CMS_MODULE
		rename
			module_api as file_upload_api
		redefine
			install,
			initialize,
			setup_hooks,
			permissions,
			file_upload_api
		end

	CMS_HOOK_MENU_SYSTEM_ALTER

	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make
		do
			name := "file_uploader"
			version := "1.0"
			description := "Service to upload files, and manage them."
			package := "file"
		end

feature -- Access

	name: STRING

	permissions: LIST [READABLE_STRING_8]
			-- List of permission ids, used by this module, and declared.
		do
			Result := Precursor
			Result.force ("admin uploaded files")
			Result.force ("upload files")
		end



feature {CMS_API} -- Module Initialization

	initialize (api: CMS_API)
			-- <Precursor>
		do
			Precursor (api)
			if file_upload_api = Void then
				create file_upload_api.make (api)
			end
		end

feature {CMS_API}-- Module management

	install (api: CMS_API)
			-- install the module
		local
			l_file_upload_api: like file_upload_api
			d: DIRECTORY
		do
			create l_file_upload_api.make (api)
			create d.make_with_path (l_file_upload_api.uploads_location)
			if not d.exists then
				d.recursive_create_dir
			end
			file_upload_api := l_file_upload_api
			Precursor (api)
		end

feature {CMS_API} -- Access: API

	file_upload_api: detachable CMS_FILE_UPLOADER_API
			-- <Precursor>		

feature -- Access: router

	setup_router (a_router: WSF_ROUTER; a_api: CMS_API)
			-- <Precursor>
		do
			map_uri_template_agent (a_router, "/upload/", agent execute_upload (?, ?, a_api), Void) -- Accepts any method GET, HEAD, POST, PUT, DELETE, ...
			map_uri_template_agent (a_router, "/upload/{filename}", agent display_uploaded_file_info (?, ?, a_api), a_router.methods_get)
			map_uri_template_agent (a_router, "/upload/remove/{filename}", agent remove (?, ?, a_api), a_router.methods_get)
		end

feature -- Hooks

	setup_hooks (a_hooks: CMS_HOOK_CORE_MANAGER)
		do
			a_hooks.subscribe_to_menu_system_alter_hook (Current)
		end

	menu_system_alter (a_menu_system: CMS_MENU_SYSTEM; a_response: CMS_RESPONSE)
		local
			link: CMS_LOCAL_LINK
		do
			-- login in demo did somehow not work
			if a_response.has_permission ("upload files") then
				create link.make ("Upload", "upload/")
				a_menu_system.primary_menu.extend (link)
			end
		end

feature -- Handler

	execute_not_found_handler (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page
		do
			res.redirect_now_with_content (req.script_url ("/"), uri + ": not found. %N Redirectioin to" + req.script_url ("/"), "text/html")
		end

	display_uploaded_file_info (req: WSF_REQUEST; res: WSF_RESPONSE; api: CMS_API)
			-- Display information related to a cms uploaded file.
		local
			body: STRING_8
			r: CMS_RESPONSE
			f: CMS_FILE
			meta_file: RAW_FILE
			fn: READABLE_STRING_32
			meta_user, meta_size, meta_time, meta_type: STRING
			size: INTEGER
		do
			check req.is_get_request_method end
			create {GENERIC_VIEW_CMS_RESPONSE} r.make (req, res, api)

				-- add style
			r.add_style (r.url ("/module/" + name + "/files/css/style_upload.css", void), void)

			create body.make_empty
			if attached {WSF_STRING} req.path_parameter ("filename") as p_filename then
				fn := p_filename.value
				body.append ("<h1>File %"" + api.html_encoded (fn) + "%"</h1>%N")
				body.append ("<div class=%"uploaded-file%">%N") -- To ease css customization.
				if attached file_upload_api as l_file_upload_api then
					f := l_file_upload_api.new_uploads_file (create {PATH}.make_from_string (fn))

					body.append ("<table><tr>")

					if attached f.location.extension as ext then
						if
							ext.is_case_insensitive_equal_general ("png")
							or ext.is_case_insensitive_equal_general ("jpg")
						then
							body.append ("<td><img src=%"" + req.script_url ("/" + l_file_upload_api.file_link (f).location) + "%" /></td>")
						else
							-- add default thumbnail
							body.append ("<td><img src=%"" + req.script_url ("/files/uploaded_files/.thumbnails/file-logo.png") + "%" /></td>")
						end
					else
							-- add default thumbnail
						body.append ("<td><img src=%"" + req.script_url ("/files/uploaded_files/.thumbnails/file-logo.png") + "%" /></td>")
					end

					create meta_file.make_with_path (l_file_upload_api.metadata_location.extended (fn).appended_with_extension ("cms-metadata"))
					-- read metadata out
					if meta_file.exists and then meta_file.is_access_readable then
						meta_file.open_read

						meta_file.read_line
						create meta_user.make_from_string (meta_file.last_string)

						meta_file.read_line
						create meta_time.make_from_string (meta_file.last_string)

						meta_file.read_line
						create meta_size.make_from_string (meta_file.last_string)

						meta_file.read_line
						create meta_type.make_from_string (meta_file.last_string)

						meta_file.close
					else
						create meta_user.make_empty
						create meta_time.make_empty
						create meta_size.make_empty
						create meta_type.make_empty
					end

					body.append ("<td>")
					if not meta_user.is_empty then
						body.append ("<strong>User: </strong>" + meta_user + "%N <br>")
					else
						body.append ("<strong>User: </strong> unknown user %N <br>")
					end

					if not meta_time.is_empty then
						body.append ("<strong>Upload Time: </strong>" + meta_time + "%N <br>")
					else
						body.append ("<strong>Upload Time: </strong> NA %N <br>")
					end


					if not meta_size.is_empty then
						size := meta_size.to_integer
						if size >= 1000000 then
							size := size // 1000000
							body.append ("<strong> File Size: </strong>" + size.out + " MB %N <br>")
						else
							if size >= 1000 then
								size := size // 1000
								body.append ("<strong> File Size: </strong>" + size.out + " kB %N <br>")
							else
								body.append ("<strong> File Size: </strong>" + size.out + " bytes %N <br>")
							end
						end
					else
						body.append ("<strong>File Size: </strong> NA %N <br>")
					end

					if not meta_type.is_empty then
						body.append ("<strong>File Type: </strong>" + meta_type + "%N <br>")
					else
						body.append ("<strong>File Type: </strong> NA %N <br>")
					end

					body.append ("<br><br>")

					body.append ("<button><a class=%"download-button%" href=%"" + req.script_url ("/" + l_file_upload_api.file_link (f).location) + "%" download>Download</a></button>%N")
					body.append ("<button><a class=%"download-button%" href=%"" + req.script_url ("/upload/remove/" + f.filename) + "%">Remove</a></button>%N")

					body.append ("</td>")
					body.append ("</tr></table>")
				end
				body.append ("%N</div>%N")
			end
			r.add_to_primary_tabs (create {CMS_LOCAL_LINK}.make ("back", "upload/"))
			r.set_main_content (body)
			r.execute
		end

	execute_upload (req: WSF_REQUEST; res: WSF_RESPONSE; api: CMS_API)
		local
			body: STRING_8
			r: CMS_RESPONSE
		do
			if req.is_get_head_request_method or req.is_post_request_method then
				create body.make_empty
				body.append ("<h1> Upload files </h1>%N")

				create {GENERIC_VIEW_CMS_RESPONSE} r.make (req, res, api)

					-- set style
				r.add_style (r.url ("/module/" + name + "/files/css/style_upload.css", void), void)

					-- add JS for dropzone
				r.add_javascript_url (r.url ("/module/" + name + "/files/javascript/dropzone.js", void))

				if r.has_permission ("upload files") then
						-- create body
					body.append ("<p>Please choose some file(s) to upload.</p>")

						-- create form to choose files and upload them
					body.append ("<form action=%"/upload/%" class=%"dropzone%" >%N")
					body.append ("</form><br>%N")
					body.append ("<div id=%"up-button-id%"><button><a class=%"upload-button%" href=%"/upload/%">Upload Files</a></button></div> <br>")

					if req.is_post_request_method then
						process_uploaded_files (req, api, body)
					end
				else
					create {FORBIDDEN_ERROR_CMS_RESPONSE} r.make (req, res, api)
				end

					-- Build the response.

				append_uploaded_file_album_to (req, api, body)

				r.set_main_content (body)
			else
				create {BAD_REQUEST_ERROR_CMS_RESPONSE} r.make (req, res, api)
			end
			r.execute
		end

	process_uploaded_files (req: WSF_REQUEST; api: CMS_API; a_output: STRING)
			-- show all newly uploaded files
		local
			l_uploaded_file: CMS_UPLOADED_FILE
			uf: WSF_UPLOADED_FILE
		do
			if attached file_upload_api as l_file_upload_api then
					-- if has uploaded files, then store them
				if req.has_uploaded_file then
					a_output.append ("<strong>Newly uploaded file(s): </strong>%N")
					a_output.append ("<ul class=%"uploaded-files%">")
					across
						req.uploaded_files as ic
					loop
						uf := ic.item
						create l_uploaded_file.make_with_uploaded_file (l_file_upload_api.uploads_location, uf)
						a_output.append ("<li>")
						a_output.append (api.html_encoded (l_uploaded_file.filename))

							-- store the just uploaded file
						l_file_upload_api.save_uploaded_file (l_uploaded_file)

							-- create medadata file
						l_uploaded_file.set_size (uf.size)
						l_uploaded_file.set_type (uf.content_type)

						create_metadata_file (l_uploaded_file, l_file_upload_api, req)

						if l_file_upload_api.error_handler.has_error then
							a_output.append (" <span class=%"error%">: upload failed!</span>")
						end
						a_output.append ("</li>")
					end
					a_output.append ("</ul>%N")
				end
			end
		end

	append_uploaded_file_album_to (req: WSF_REQUEST; api: CMS_API; a_output: STRING)
		local
			d: DIRECTORY
			f: CMS_FILE
			p: PATH
			rel: PATH
			meta_file: RAW_FILE
			meta_user, meta_time, meta_size, file_name: STRING
			size: INTEGER
		do
			if attached file_upload_api as l_file_upload_api then
				create rel.make_from_string (l_file_upload_api.uploads_directory_name)
				p := api.files_location.extended_path (rel)

				a_output.append ("<strong>All uploaded files:</strong>%N")
				a_output.append ("<table class=%"directory-index%">%N")
				a_output.append ("<tr><th>Filename</th><th>Uploading Time</th><th>User</th><th>Size</th><th></th><th></th></tr>%N")

				create d.make_with_path (p)
				if d.exists then
					across
						d.entries as ic
					loop

						if ic.item.is_current_symbol then
								-- Ignore
						elseif ic.item.is_parent_symbol then
								-- Ignore for now.
						else
							f := l_file_upload_api.new_file (rel.extended_path (ic.item))

								-- check if f is directory -> yes, then do not show
							if not f.is_directory then

								create file_name.make_from_string (f.filename)

								create meta_file.make_with_path (l_file_upload_api.metadata_location.extended (file_name).appended_with_extension ("cms-metadata"))

									-- read metadata out
								if meta_file.exists and then meta_file.is_access_readable then
									meta_file.open_read

									meta_file.read_line
									create meta_user.make_from_string (meta_file.last_string)

									meta_file.read_line
									create meta_time.make_from_string (meta_file.last_string)

									meta_file.read_line
									create meta_size.make_from_string (meta_file.last_string)

									meta_file.close
								else
									create meta_user.make_empty
									create meta_time.make_empty
									create meta_size.make_empty
								end
								a_output.append ("<tr class=%"directory-index%">")

									-- add filename
								a_output.append ("<td>")
								a_output.append ("<a href=%"" + api.percent_encoded (f.filename) + "%">")
								a_output.append (api.html_encoded (f.filename))
								a_output.append ("</a>")
								a_output.append ("</td>%N")

									-- add uploading time
								a_output.append ("<td>")
								if not meta_time.is_empty then
									a_output.append (meta_time)
								else
									a_output.append ("NA")
								end
								a_output.append ("</td>%N")

									-- add user
								a_output.append ("<td>")
								if not meta_user.is_empty then
									a_output.append (meta_user)
								else
									a_output.append ("unknown user")
								end
								a_output.append ("</td>%N")

									-- add size
								a_output.append ("<td>")
								if not meta_size.is_empty then
									size := meta_size.to_integer
									if size >= 1000000 then
										size := size // 1000000
										a_output.append (size.out + " MB")
									else
										if size >= 1000 then
											size := size // 1000
											a_output.append (size.out + " kB")
										else
											a_output.append (size.out + " bytes")
										end
									end
								else
									a_output.append ("NA")
								end
								a_output.append ("</td>%N")

									-- add download link
								a_output.append ("<td>")
								a_output.append ("<button><a class=%"download-button%" href=%"" + req.script_url ("/" + l_file_upload_api.file_link (f).location) + "%" download>Download</a></button>%N")
								a_output.append ("</td>%N")

									-- add remove button
								a_output.append ("<td>")
								a_output.append ("<button><a class=%"download-button%" href=%"" + req.script_url ("/upload/remove/" + f.filename) + "%">Remove</a></button>%N")
								a_output.append ("</td>%N")

								a_output.append ("</tr>%N")
							else
								if f.filename.at (1) /= '.' then

									-- folder support not yet supported

--										-- add directory identifier
--									a_output.append ("<td>[dir]</td>%N")

--									a_output.append ("<td>")
--									a_output.append ("<a href=%"" + api.percent_encoded (f.filename) + "%">")
--									a_output.append (api.html_encoded (f.filename))
--									a_output.append ("</a>")
--									a_output.append ("</td>%N")

--									a_output.append ("<td></td><td></td><td></td><td></td><td></td>")
								end

							end
						end
					end
				end
				a_output.append ("</table>%N")
			end
		end


	create_metadata_file (uf: CMS_UPLOADED_FILE; api: CMS_FILE_UPLOADER_API; req: WSF_REQUEST)
		local
			raw: RAW_FILE
			upload_time: DATE_TIME
		do
			-- create a file for metadata
				create raw.make_with_path (api.metadata_location.extended (uf.filename).appended_with_extension ("cms-metadata"))

				if raw.exists then
					raw.open_write
				else
					raw.create_read_write
				end
					-- insert username
				if attached api.cms_api.current_user (req) as user then
					raw.put_string (user.name)
					raw.put_new_line
				end
					-- insert uploaded_time
				create upload_time.make_now
				raw.put_string (upload_time.out)
				raw.put_new_line

					-- insert size of file
				raw.put_string (uf.size.out)
				raw.put_new_line

					-- insert file type
				if attached uf.type as type then
					raw.put_string (type.out)
					raw.put_new_line
				end

				raw.close
		end

		remove (req: WSF_REQUEST; res: WSF_RESPONSE; api: CMS_API)
			local
				raw_file, meta_file: RAW_FILE
				body: STRING
				r: CMS_RESPONSE
				path, meta_path: PATH
			do
				if attached {WSF_STRING} req.path_parameter ("filename") as p_filename then
					if attached file_upload_api as l_file_upload_api then
						create path.make_from_string (l_file_upload_api.uploads_location.extended (p_filename.value).out)
						create meta_path.make_from_string (l_file_upload_api.metadata_location.extended (p_filename.value + ".cms-metadata").out)
					else
						create path.make_empty
						create meta_path.make_empty
					end

					create raw_file.make_with_path (path)
					create meta_file.make_with_path (meta_path)

					if raw_file.exists then
						raw_file.delete
					end
					if meta_file.exists then
						meta_file.delete
					end

				end

				create {GENERIC_VIEW_CMS_RESPONSE} r.make (req, res, api)
				create body.make_empty

				body.append ("<h3>The file has been removed successfully!</a></h3>")

				r.add_to_primary_tabs (create {CMS_LOCAL_LINK}.make ("back", "upload/"))
				r.set_main_content (body)
				r.execute
			end

feature -- Mapping helper: uri template agent (analogue to the demo-module)

	map_uri_template (a_router: WSF_ROUTER; a_tpl: STRING; h: WSF_URI_TEMPLATE_HANDLER; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map `h' as handler for `a_tpl', according to `rqst_methods'.
		require
			a_tpl_attached: a_tpl /= Void
			h_attached: h /= Void
		do
			a_router.map (create {WSF_URI_TEMPLATE_MAPPING}.make (a_tpl, h), rqst_methods)
		end

	map_uri_template_agent (a_router: WSF_ROUTER; a_tpl: READABLE_STRING_8; proc: PROCEDURE [TUPLE [req: WSF_REQUEST; res: WSF_RESPONSE]]; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map `proc' as handler for `a_tpl', according to `rqst_methods'.
		require
			a_tpl_attached: a_tpl /= Void
			proc_attached: proc /= Void
		do
			map_uri_template (a_router, a_tpl, create {WSF_URI_TEMPLATE_AGENT_HANDLER}.make (proc), rqst_methods)
		end

end
