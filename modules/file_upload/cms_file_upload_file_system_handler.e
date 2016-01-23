note
	description: "Summary description for {CMS_FILE_UPLOAD_FILE_SYSTEM_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_FILE_UPLOAD_FILE_SYSTEM_HANDLER

inherit
	WSF_FILE_SYSTEM_HANDLER
		redefine
			process_index
		end

create
	make_with_p

feature -- Initialization

	make_with_p (d: like document_root)
		do
			if d.is_empty then
					document_root := execution_environment.current_working_path
				else
					document_root := d
				end
			ensure
				not document_root.is_empty
		end

feature -- process function

	process_index (a_uri: READABLE_STRING_8; dn: PATH; req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
			uri, s: STRING_8
			d: DIRECTORY
			l_files: LIST [PATH]
			p: PATH
			n: READABLE_STRING_32
			httpdate: HTTP_DATE
			pf: RAW_FILE
			l_is_dir: BOOLEAN
		do
			create d.make_with_path (dn)
			d.open_read
			if attached directory_index_file (d) as f then
				process_file (f, req, res)
			else
				uri := a_uri
				if not uri.is_empty and then uri [uri.count] /= '/'  then
					uri.append_character ('/')
				end
				s := "[
					<html>
						<head>
							<title>All uploaded files in $URI</title>
							<style>
								td { padding-left: 10px;}
							</style>
						</head>
						<body>
							<h1>Index of $URI</h1>
							<table>
							<tr><th/><th>Name</th><th>Last modified</th><th>Size</th></tr>
							<tr><th colspan="4"><hr></th></tr>
					]"
				s.replace_substring_all ("$URI", uri)

				from
					l_files := d.entries
					l_files.start
				until
					l_files.after
				loop
					p := l_files.item
					if ignoring_index_entry (p) then

					else
						n := p.name
						create pf.make_with_path (dn.extended_path (p))
						if pf.exists and then pf.is_directory then
							l_is_dir := True
						else
							l_is_dir := False
						end

						s.append ("<tr><td>")
						if l_is_dir then
							s.append ("[dir]")
						else
							s.append ("&nbsp;")
						end
						s.append ("</td>")
						s.append ("<td><a href=%"" + uri)
						url_encoder.append_percent_encoded_string_to (n, s)
						s.append ("%">")
						if p.is_parent_symbol then
							s.append ("[Parent Directory] ..")
						else
							s.append (html_encoder.encoded_string (n))
						end
						if l_is_dir then
							s.append ("/")
						end

						s.append ("</td>")
						s.append ("<td>")
						if pf.exists then
							create httpdate.make_from_date_time (file_date (pf))
							httpdate.append_to_rfc1123_string (s)
						end
						s.append ("</td>")
						s.append ("<td>")
						if not l_is_dir and pf.exists then
							s.append_integer (file_size (pf))
						end
						s.append ("</td>")
						s.append ("</tr>")
					end
					l_files.forth
				end
				s.append ("[
							<tr><th colspan="4"><hr></th></tr>				
							</table>
						</body>
					</html>
					]"
				)

				create h.make
				h.put_content_type_text_html
				res.set_status_code ({HTTP_STATUS_CODE}.ok)
				h.put_content_length (s.count)
				res.put_header_lines (h)
				if not req.request_method.same_string ({HTTP_REQUEST_METHODS}.method_head) then
					res.put_string (s)
				end
				res.flush
			end
			d.close
		end

end
