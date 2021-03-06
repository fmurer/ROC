note
	description: "Summary description for {CMS_NODE_TYPE_WEBFORM_MANAGER}."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CMS_NODE_TYPE_WEBFORM_MANAGER [G -> CMS_NODE]

inherit
	CMS_NODE_TYPE_WEBFORM_MANAGER_I [G]

	SHARED_WSF_PERCENT_ENCODER

feature -- Forms ...		

	populate_form (response: NODE_RESPONSE; f: CMS_FORM; a_node: detachable CMS_NODE)
		local
			ti: WSF_FORM_TEXT_INPUT
			fset: WSF_FORM_FIELD_SET
			ta, sum: CMS_FORM_TEXTAREA
			tselect: WSF_FORM_SELECT
			opt: WSF_FORM_SELECT_OPTION
			cms_format: CMS_EDITOR_CONTENT_FORMAT
		do
			create cms_format

			create ti.make ("title")
			ti.enable_required
			ti.set_label ("Title")
			ti.set_size (70)
			if a_node /= Void then
				ti.set_text_value (a_node.title)
			end
			f.extend (ti)

			f.extend_html_text ("<br/>")

				-- Select field has to be initialized before textareas are replaced, because they depend on the selection of the field
			create tselect.make ("format")
			tselect.set_label ("Format for content (and summary)")
			tselect.set_is_required (True)

				-- Main Content
			create ta.make ("content")
			ta.set_rows (10)
			ta.set_cols (70)
			ta.show_as_editor_if_selected (tselect, cms_format.name)
			if a_node /= Void then
				ta.set_text_value (a_node.content)
			end
			ta.set_label (response.translation ("Content", Void))
			ta.set_description (response.translation ("This is the main content", Void))
			ta.set_is_required (False)

				-- Summary
			create sum.make ("summary")
			sum.set_rows (3)
			sum.set_cols (70)
				-- if cms_html is selected
			sum.show_as_editor_if_selected (tselect, cms_format.name)
			if a_node /= Void then
				sum.set_text_value (a_node.summary)
			end
			sum.set_label (response.translation ("Summary", Void))
			sum.set_description (response.translation ("Text displayed in short view.", Void))
			sum.set_is_required (False)

			create fset.make

				-- Add summary
			fset.extend (sum)
			fset.extend_html_text("<br/>")

				-- Add content
			fset.extend (ta)
			fset.extend_html_text ("<br/>")

			across
				 content_type.available_formats as c
			loop
				create opt.make (c.item.name, c.item.title)
				if attached c.item.html_help as f_help then
					opt.set_description ("<ul>" + f_help + "</ul>")
				end
				tselect.add_option (opt)
			end
			if a_node /= Void and then attached a_node.format as l_format then
				tselect.set_text_by_value (l_format)
			end

			fset.extend (tselect)

			f.extend (fset)

				-- Path alias
			populate_form_with_taxonomy (response, f, a_node)
			populate_form_with_path_alias (response, f, a_node)
		end

	populate_form_with_taxonomy (response: CMS_RESPONSE; f: CMS_FORM; a_content: detachable CMS_CONTENT)
		do
			if attached {CMS_TAXONOMY_API} response.api.module_api ({CMS_TAXONOMY_MODULE}) as l_taxonomy_api then
				l_taxonomy_api.populate_edit_form (response, f, content_type.name, a_content)
			end
		end

	populate_form_with_path_alias (response: NODE_RESPONSE; f: CMS_FORM; a_node: detachable CMS_NODE)
		local
			ti: WSF_FORM_TEXT_INPUT
			l_uri: detachable READABLE_STRING_8
			l_iri: detachable READABLE_STRING_32
		do
				-- Path alias		
			create ti.make ("path_alias")
			ti.set_label ("Path")
			ti.set_pattern ("^([A-Za-z0-9-_+ ]).+")
			ti.set_description ("Path alias pattern: ^([A-Za-z0-9-_+ ]).+  For example resource/page1 ")
			ti.set_size (70)
			if a_node /= Void and then a_node.has_id then
				if attached a_node.link as lnk then
					l_uri := lnk.location
				else
					l_iri := percent_encoder.percent_decoded_string (response.api.location_alias (response.node_api.node_path (a_node)))
					l_uri := l_iri.to_string_8
				end
				ti.set_text_value (l_uri)
				ti.set_description ("Optionally specify an alternative URL path by which this content can be accessed. For example, type 'about' when writing an about page. Use a relative path or the URL alias won't work.")
			end
			ti.set_validation_action (agent (fd: WSF_FORM_DATA; ia_response: NODE_RESPONSE; ia_node: detachable CMS_NODE)
					do
						if
							attached fd.string_item ("path_alias") as f_path_alias
						then
							if ia_response.api.is_valid_path_alias (f_path_alias) then
									-- Ok.
							elseif f_path_alias.is_empty then
									-- Ok
							elseif f_path_alias.starts_with_general ("/") then
								fd.report_invalid_field ("path_alias", "Path alias should not start with a slash '/' .")
							elseif f_path_alias.has_substring ("://") then
								fd.report_invalid_field ("path_alias", "Path alias should not be absolute url .")
							else
									-- TODO: implement full path alias validation
							end
							if
								attached ia_response.api.source_of_path_alias (f_path_alias) as l_aliased_location and then
								((ia_node /= Void and then ia_node.has_id) implies not l_aliased_location.same_string (ia_response.node_api.node_path (ia_node)))
							then
								fd.report_invalid_field ("path_alias", "Path is already aliased to location %"" + ia_response.link (Void, l_aliased_location, Void) + "%" !")
							end
						end
					end(?, response, a_node)
				)
			if
				attached f.fields_by_name ("title") as l_title_fields and then
				attached l_title_fields.first as l_title_field
			then
				f.insert_after (ti, l_title_field)
			else
				f.extend (ti)
			end
		end

	update_node	(response: NODE_RESPONSE; fd: WSF_FORM_DATA; a_node: CMS_NODE)
		local
			b,s: detachable READABLE_STRING_32
			f: detachable CONTENT_FORMAT
		do
			if attached fd.integer_item ("id") as l_id and then l_id > 0 then
				check a_node.id = l_id end
			end
			if attached fd.string_item ("title") as l_title then
				a_node.set_title (l_title)
			end

			if attached fd.string_item ("content") as l_content then
				b := l_content
			end

			-- Read out the summary field from the form data
			if attached fd.string_item ("summary") as l_summary then
				s := l_summary
			end

			if attached fd.string_item ("format") as s_format and then attached response.api.format (s_format) as f_format then
				f := f_format
			elseif a_node /= Void and then attached a_node.format as s_format and then attached response.api.format (s_format) as f_format then
				f := f_format
			else
				f := cms_api.formats.default_format
			end

			-- Update node with summary and body content
			if b /= Void then
				a_node.set_content (b, s, f.name)
			end

			-- Update author
			a_node.set_author (response.user)
		end

	new_node (response: NODE_RESPONSE; fd: WSF_FORM_DATA; a_node: detachable CMS_NODE): G
			-- <Precursor>
		local
			b,s: detachable READABLE_STRING_32
			f: detachable CONTENT_FORMAT
			l_node: detachable like new_node
		do
			if attached {like new_node} a_node as l_arg_node then
				l_node := l_arg_node
			else
				l_node := content_type.new_node (a_node)
			end
			if attached fd.integer_item ("id") as l_id and then l_id > 0 then
				if l_node /= Void then
					check l_node.id = l_id end
				else
					if attached {like new_node} response.node_api.node (l_id) as n then
						l_node := n
					else
						-- FIXME: Error
					end
				end
			end
			if attached fd.string_item ("title") as l_title then
				if l_node = Void then
					l_node := content_type.new_node (Void)
					l_node.set_title (l_title)
				else
					l_node.set_title (l_title)
				end
			else
				if l_node = Void then
					l_node := content_type.new_node_with_title ("...", Void)
				end
			end
			l_node.set_author (response.user)

				--Summary
			if attached fd.string_item ("summary") as l_summary then
				s := l_summary
			end

				--Content
			if attached fd.string_item ("content") as l_content then
				b := l_content
			end

			if attached fd.string_item ("format") as s_format and then attached response.api.format (s_format) as f_format then
				f := f_format
			elseif a_node /= Void and then attached a_node.format as s_format and then attached response.api.format (s_format) as f_format then
				f := f_format
			else
				f := cms_api.formats.default_format
			end

			-- Update node with summary and content
			if b /= Void then
				l_node.set_content (b, s, f.name)
			end
			Result := l_node
		end

feature -- Output

	append_content_as_html_to (a_node: G; is_teaser: BOOLEAN; a_output: STRING; a_response: detachable CMS_RESPONSE)
			-- <Precursor>
		local
			lnk: detachable CMS_LOCAL_LINK
			hdate: HTTP_DATE
			l_node_api: CMS_NODE_API
		do
			l_node_api := node_api

				-- Show tabs only if a user is authenticated.
			if
				not is_teaser and then
				a_response /= Void and then
				attached a_response.user as l_user
			then
				lnk := a_node.link
				if lnk /= Void then
					lnk := a_response.local_link (a_response.translation ("View", Void), lnk.location)
				else
					lnk := a_response.local_link (a_response.translation ("View", Void), l_node_api.node_path (a_node))
				end
				lnk.set_weight (1)
				a_response.add_to_primary_tabs (lnk)

				if a_node.status = {CMS_NODE_API}.trashed then
					create lnk.make ("Delete", l_node_api.node_path (a_node) + "/delete")
					lnk.set_weight (2)
					a_response.add_to_primary_tabs (lnk)
				elseif a_node.has_id then
						-- Node in {{CMS_NODE_API}.published} or {CMS_NODE_API}.not_published} status.
					create lnk.make ("Edit", l_node_api.node_path (a_node) + "/edit")
					lnk.set_weight (2)
					a_response.add_to_primary_tabs (lnk)
					if
						l_node_api.has_permission_for_action_on_node ("view revisions", a_node, l_user)
					then
						create lnk.make ("Revisions", l_node_api.node_path (a_node) + "/revision")
						lnk.set_weight (3)
						a_response.add_to_primary_tabs (lnk)
					end

					if
						l_node_api.has_permission_for_action_on_node ("trash", a_node, l_user)
					then
						create lnk.make ("Move to trash", l_node_api.node_path (a_node) + "/trash")
						lnk.set_weight (3)
						a_response.add_to_primary_tabs (lnk)
					end
				end
			end
			a_output.append ("<div class=%"")
			if is_teaser then
				a_output.append (" cms-teaser")
			end
			a_output.append ("cms-node node-" + a_node.content_type + "%">")

			a_output.append ("<div class=%"info%"> ")
			if attached a_node.author as l_author then
				a_output.append (" by ")
				a_output.append (l_node_api.html_encoded (l_author.name))
			end
			if attached a_node.modification_date as l_modified then
				a_output.append (" (modified: ")
				create hdate.make_from_date_time (l_modified)
				a_output.append (hdate.yyyy_mmm_dd_string)
				a_output.append (")")
			end
			a_output.append ("</div>")

			if
				a_response /= Void and then
				attached {CMS_TAXONOMY_API} cms_api.module_api ({CMS_TAXONOMY_MODULE}) as l_taxonomy_api
			then
				l_taxonomy_api.append_taxonomy_to_xhtml (a_node, a_response, a_output)
			end

			-- We don't show the summary on the detail page, since its just a short view of the full content. Otherwise we would write the same thing twice.
			-- The usage of the summary is to give a short overview in the list of nodes or for the meta tag "description"
			if is_teaser then
				if attached a_node.summary as l_summary then
					a_output.append ("<p class=%"summary%">")
					if attached cms_api.format (a_node.format) as f then
						append_formatted_content_to (l_summary, f, a_output)
					else
						append_formatted_content_to (l_summary, cms_api.formats.default_format, a_output)
					end
					a_output.append ("</p>")
				end
			elseif attached a_node.content as l_content then
				a_output.append ("<p class=%"content%">")
				if attached cms_api.format (a_node.format) as f then
					append_formatted_content_to (l_content, f, a_output)
				else
					append_formatted_content_to (l_content, cms_api.formats.default_format, a_output)
				end
				a_output.append ("</p>")
			end
			a_output.append ("</div>")
		end

end

