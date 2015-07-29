note
	description: "Summary description for {CMS_ROLE_FORM_RESPONSE}."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_ROLE_FORM_RESPONSE

inherit

	CMS_RESPONSE
		redefine
			make,
			initialize,
			custom_prepare
		end

create
	make

feature {NONE} -- Initialization

	make (req: WSF_REQUEST; res: WSF_RESPONSE; a_api: like api)
		do
			create {WSF_NULL_THEME} wsf_theme.make
			Precursor (req, res, a_api)
		end

	initialize
		do
			Precursor
			create {CMS_TO_WSF_THEME} wsf_theme.make (Current, theme)
		end

	wsf_theme: WSF_THEME

feature -- Query

	role_id_path_parameter (req: WSF_REQUEST): INTEGER_64
			-- Role id passed as path parameter for request `req'.
		local
			s: STRING
		do
			if attached {WSF_STRING} req.path_parameter ("id") as p_nid then
				s := p_nid.value
				if s.is_integer_64 then
					Result := s.to_integer_64
				end
			end
		end

feature -- Process

	process
			-- Computed response message.
		local
			b: STRING_8
			uid: INTEGER_64
			user_api: CMS_USER_API
		do
			user_api := api.user_api
			create b.make_empty
			uid := role_id_path_parameter (request)
			if uid > 0 and then attached user_api.user_role_by_id (uid.to_integer) as l_role then
				fixme ("refactor: process_edit, process_create process edit")
				if request.path_info.ends_with_general ("/edit") then
					edit_form (l_role)
				elseif request.path_info.ends_with_general ("/delete") then
					delete_form (l_role)
				end
			else
				new_form
			end
		end

feature -- Process Edit

	edit_form (a_role: CMS_USER_ROLE)
		local
			f: like new_edit_form
			b: STRING
			fd: detachable WSF_FORM_DATA
		do
			create b.make_empty
			f := new_edit_form (a_role, url (request.path_info, Void), "edit-user")
			invoke_form_alter (f, fd)
			if request.is_post_request_method then
				f.validation_actions.extend (agent edit_form_validate(?,a_role, b))
				f.submit_actions.extend (agent edit_form_submit(?, a_role, b))
				f.process (Current)
				fd := f.last_data
			end
			if a_role.has_id then
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("View", Void), "admin/role/" + a_role.id.out), primary_tabs)
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("Edit", Void), "admin/role/" + a_role.id.out + "/edit"), primary_tabs)
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("Delete", Void), "admin/role/" + a_role.id.out + "/delete"), primary_tabs)
			end
			if attached redirection as l_location then
					-- FIXME: Hack for now
				set_title (a_role.name)
				b.append (html_encoded (a_role.name) + " saved")
			else
				set_title (formatted_string (translation ("Edit $1 #$2", Void), [a_role.name, a_role.id]))
				f.append_to_html (wsf_theme, b)
			end
			set_main_content (b)
		end

feature -- Process Delete

	delete_form (a_role: CMS_USER_ROLE)
		local
			f: like new_delete_form
			b: STRING
			fd: detachable WSF_FORM_DATA
		do
			create b.make_empty
			f := new_delete_form (a_role, url (request.path_info, Void), "edit-user")
			invoke_form_alter (f, fd)
			if request.is_post_request_method then
				f.process (Current)
				fd := f.last_data
			end
			if a_role.has_id then
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("View", Void), "admin/role/" + a_role.id.out), primary_tabs)
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("Edit", Void), "admin/role/" + a_role.id.out + "/edit"), primary_tabs)
				add_to_menu (create {CMS_LOCAL_LINK}.make (translation ("Delete", Void), "admin/role/" + a_role.id.out + "/delete"), primary_tabs)
			end
			if attached redirection as l_location then
					-- FIXME: Hack for now
				set_title (a_role.name)
				b.append (html_encoded (a_role.name) + " deleted")
			else
				set_title (formatted_string (translation ("Delete $1 #$2", Void), [a_role.name, a_role.id]))
				f.append_to_html (wsf_theme, b)
			end
			set_main_content (b)
		end

feature -- Process New

	new_form
		local
			f: like new_edit_form
			b: STRING
			fd: detachable WSF_FORM_DATA
			l_role: detachable CMS_USER_ROLE
		do
			create b.make_empty
			f := new_edit_form (l_role, url (request.path_info, Void), "create-role")
			invoke_form_alter (f, fd)
			if request.is_post_request_method then
				f.validation_actions.extend (agent new_form_validate(?, b))
				f.submit_actions.extend (agent edit_form_submit(?, l_role, b))
				f.process (Current)
				fd := f.last_data
			end
			if attached redirection as l_location then
					-- FIXME: Hack for now
				if attached l_role then
					set_title (l_role.name)
					b.append (html_encoded (l_role.name) + " Saved")
				end
			else
				if attached l_role then
					set_title (formatted_string (translation ("Saved $1 #$2", Void), [l_role.name, l_role.id]))
				end
				f.append_to_html (wsf_theme, b)
			end
			set_main_content (b)
		end

feature -- Form

	edit_form_submit (fd: WSF_FORM_DATA; a_role: detachable CMS_USER_ROLE; b: STRING)
		local
			l_save_role: BOOLEAN
			l_update_role: BOOLEAN
			l_role: detachable CMS_USER_ROLE
			s: STRING
			lnk: CMS_LINK
		do
			l_save_role := attached {WSF_STRING} fd.item ("op") as l_op and then l_op.same_string ("Create role")
			if l_save_role then
				debug ("cms")
					across
						fd as c
					loop
						b.append ("<li>" + html_encoded (c.key) + "=")
						if attached c.item as v then
							b.append (html_encoded (v.string_representation))
						end
						b.append ("</li>")
					end
				end
				create_role (fd)
			end
			l_update_role := attached {WSF_STRING} fd.item ("op") as l_op and then l_op.same_string ("Update role")
			if l_update_role then
				debug ("cms")
					across
						fd as c
					loop
						b.append ("<li>" + html_encoded (c.key) + "=")
						if attached c.item as v then
							b.append (html_encoded (v.string_representation))
						end
						b.append ("</li>")
					end
				end
				if attached a_role as u_role then
					update_role (fd, u_role)
				else
					fd.report_error ("Missing Role")
				end
			end
		end

	edit_form_validate (fd: WSF_FORM_DATA; a_role: CMS_USER_ROLE; b: STRING)
		do
			if attached fd.string_item ("op") as f_op then
				if f_op.is_case_insensitive_equal_general ("Update role") then
					if
						attached fd.string_item ("role") as l_role and then
					   	not a_role.name.is_case_insensitive_equal (l_role)
					then
						if attached api.user_api.user_role_by_name (l_role) then
							fd.report_invalid_field ("role", "Role already taken!")
						end
					else
						if fd.string_item ("role") = Void then
							fd.report_invalid_field ("role", "missing role")
						end
					end
					if attached {WSF_TABLE} fd.item ("cms_perm[]") as l_perm then
						a_role.permissions.compare_objects
						from
							l_perm.values.start
						until
							l_perm.values.after
						loop
							if attached {WSF_STRING} l_perm.value (l_perm.values.key_for_iteration) as l_value then
								if a_role.permissions.has (l_value.value) then
									fd.report_invalid_field ("cms_perm[]", "Permission " + l_value.value + " already taken!")
								end
							end
							l_perm.values.forth
						end
					end
				end
			end
		end

	new_edit_form (a_role: detachable CMS_USER_ROLE; a_url: READABLE_STRING_8; a_name: STRING;): CMS_FORM
			-- Create a web form named `a_name' for uSER `a_YSER' (if set), using form action url `a_url'.
		local
			f: CMS_FORM
			th: WSF_FORM_HIDDEN_INPUT
		do
			create f.make (a_url, a_name)
			create th.make ("role-id")
			if a_role /= Void then
				th.set_text_value (a_role.id.out)
			else
				th.set_text_value ("0")
			end
			f.extend (th)
			populate_form (f, a_role)
			Result := f
		end

	new_form_validate (fd: WSF_FORM_DATA; b: STRING)
		do
			if attached fd.string_item ("op") as f_op then
				if f_op.is_case_insensitive_equal_general ("Create role") then
					if attached fd.string_item ("role") as l_role then
						if attached api.user_api.user_role_by_name (l_role) then
							fd.report_invalid_field ("role", "Role already taken!")
						end
					else
						fd.report_invalid_field ("role", "missing role")
					end
				end
			end
		end

	new_delete_form (a_role: detachable CMS_USER_ROLE; a_url: READABLE_STRING_8; a_name: STRING;): CMS_FORM
			-- Create a web form named `a_name' for node `a_user' (if set), using form action url `a_url'.
		local
			f: CMS_FORM
			ts: WSF_FORM_SUBMIT_INPUT
		do
			create f.make (a_url, a_name)
			f.extend_html_text ("<br/>")
			f.extend_html_text ("<legend>Are you sure you want to delete?</legend>")

				-- TODO check if we need to check for has_permissions!!
			if a_role /= Void and then a_role.has_id then
				create ts.make ("op")
				ts.set_default_value ("Delete")
				fixme ("[
					ts.set_default_value (translation ("Delete"))
				]")
				f.extend (ts)
				create ts.make ("op")
				ts.set_default_value ("Cancel")
				ts.set_formmethod ("GET")
				ts.set_formaction ("/admin/role/" + a_role.id.out)
				f.extend (ts)
			end
			Result := f
		end

	populate_form (a_form: WSF_FORM; a_role: detachable CMS_USER_ROLE)
			-- Fill the web form `a_form' with data from `a_node' if set,
			-- and apply this to content type `a_content_type'.
		local
			ti: WSF_FORM_TEXT_INPUT
			fe: WSF_FORM_EMAIL_INPUT
			fs: WSF_FORM_FIELD_SET
			cb: WSF_FORM_CHECKBOX_INPUT
			ts: WSF_FORM_SUBMIT_INPUT
		do
			if attached a_role as l_role then
				create fs.make
				fs.set_legend ("User Role")
				create ti.make_with_text ("role", a_role.name)
				ti.set_label ("Role")
				ti.enable_required
				fs.extend (ti)
				a_form.extend (fs)

				a_form.extend_html_text ("<br/>")


				create fs.make
				fs.set_legend ("Permissions")

				if not l_role.permissions.is_empty then
					across l_role.permissions as ic loop
						create cb.make_with_value ("cms_permissions", ic.item)
						cb.set_checked (True)
						cb.set_label (ic.item)
						fs.extend (cb)
					end
				end
				fs.extend_html_text ("<div class=%"input_fields_wrap%"><button class=%"add_field_button%">Add More Permissions</button></div>")
				create ti.make ("cms_perm[]")
				fs.extend (ti)

				a_form.extend (fs)
				add_javascript_content (script_add_remove_items)

				create ts.make ("op")
				ts.set_default_value ("Update role")
				a_form.extend (ts)
				a_form.extend_html_text ("<hr>")

			else
				create fs.make
				fs.set_legend ("User Role")
				create ti.make ("role")
				ti.set_label ("Role")
				ti.enable_required
				fs.extend (ti)
				a_form.extend (fs)
				a_form.extend_html_text ("<br/>")
				create ts.make ("op")
				ts.set_default_value ("Create role")
				a_form.extend (ts)
				a_form.extend_html_text ("<hr>")
			end
		end

	update_role (a_form_data: WSF_FORM_DATA; a_role: CMS_USER_ROLE)
			-- Update node `a_node' with form_data `a_form_data' for the given content type `a_content_type'.
		local
			l_permissions: LIST [READABLE_STRING_8]
		do
			if attached a_form_data.string_item ("op") as f_op then
				if f_op.is_case_insensitive_equal_general ("Update role") then
					if
						attached a_form_data.string_item("role") as l_role_name and then
						attached a_form_data.string_item ("role-id") as l_role_id
						and then attached {CMS_USER_ROLE} api.user_api.user_role_by_id (l_role_id.to_integer) as l_role
					then
						l_permissions := a_role.permissions
						l_permissions.compare_objects
						if attached {WSF_STRING} a_form_data.item ("cms_permissions") as u_role then
							a_role.permissions.wipe_out
							a_role.add_permission (u_role.value)
						elseif attached {WSF_MULTIPLE_STRING} a_form_data.item ("cms_permissions") as u_permissions then
							across
								u_permissions as ic
							loop
								if not l_permissions.has (ic.item.value) then
									a_role.remove_permission (ic.item.value)
								end
							end
						else
							a_role.permissions.wipe_out
						end
						if attached {WSF_TABLE} a_form_data.item ("cms_perm[]") as l_perm then
							a_role.permissions.compare_objects
							from
								l_perm.values.start
							until
								l_perm.values.after
							loop
								if
									attached {WSF_STRING} l_perm.value (l_perm.values.key_for_iteration) as l_value and then
									not l_value.value.is_whitespace
								then
									a_role.add_permission (l_value.value)
								end
								l_perm.values.forth
							end
						end

						if not a_form_data.has_error then
							a_role.set_name (l_role_name)
							api.user_api.save_user_role (a_role)
							add_success_message ("Permissions updated")
						end

					else
						a_form_data.report_error ("Missing Role")
					end
				end
			end
		end

	create_role (a_form_data: WSF_FORM_DATA)
		local
			u: CMS_USER_ROLE
		do
			if attached a_form_data.string_item ("op") as f_op then
				if f_op.is_case_insensitive_equal_general ("Create role") then
					if attached a_form_data.string_item ("role") as l_role then
						create u.make (l_role)
						api.user_api.save_user_role (u)
						if api.user_api.has_error then
								-- handle error
						else
							add_success_message ("Created Role")
						end
					else
						a_form_data.report_invalid_field ("username", "Missing role!")
					end
				end
			end
		end

feature -- Generation

	custom_prepare (page: CMS_HTML_PAGE)
		do
			if attached variables as l_variables then
				across
					l_variables as c
				loop
					page.register_variable (c.item, c.key)
				end
			end
		end


	script_add_remove_items: STRING = "[
				$(document).ready(function() {
			    var max_fields      = 10; //maximum input boxes allowed
			    var wrapper         = $(".input_fields_wrap"); //Fields wrapper
			    var add_button      = $(".add_field_button"); //Add button ID
			    
			    var x = 1; //initlal text box count
			    $(add_button).click(function(e){ //on add input button click
			        e.preventDefault();
			        if(x < max_fields){ //max input box allowed
			            x++; //text box increment
			            $(wrapper).append('<div><input type="text" name="cms_perm[]"/><a href="#" class="remove_field">Remove</a></div>'); //add input box
			        }
			    });
			    
			    $(wrapper).on("click",".remove_field", function(e){ //user click on remove text
			        e.preventDefault(); $(this).parent('div').remove(); x--;
			    })
			});
	]"

end
