note
	description: "[
				CMS Layout providing file system locations for
						- config 
						- application 
						- logs 
						- documentation 
						- themes
			]"
	date: "$Date: 2014-12-18 16:37:11 +0100 (jeu., 18 déc. 2014) $"
	revision: "$Revision: 96383 $"

class
	CMS_LAYOUT

inherit

	APPLICATION_LAYOUT

create
	make_default,
	make_with_path


feature -- Access

	theme_path: PATH
			-- Directory for templates (HTML, etc).
		local
			p: detachable PATH
		do
			p := internal_theme_path
			if p = Void then
				p := www_path.extended ("theme")
				internal_theme_path := p
			end
			Result := p
		end

	cms_config_ini_path: PATH
			-- CMS Configuration file path.
		local
			p: detachable PATH
		do
			p := internal_cms_config_ini_path
			if p = Void then
				p := config_path.extended ("cms.ini")
				internal_cms_config_ini_path := p
			end
			Result := p
		end

feature {NONE} -- Implementation

	internal_theme_path: detachable like theme_path

	internal_cms_config_ini_path: detachable like cms_config_ini_path

end
