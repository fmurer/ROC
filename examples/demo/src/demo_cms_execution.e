note
	description: "[
			CMS Execution for the demo server.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	DEMO_CMS_EXECUTION

inherit
	CMS_EXECUTION

create
	make

feature {NONE} -- Initialization

	initial_cms_setup: CMS_DEFAULT_SETUP
			-- CMS setup.
		local
			l_env: CMS_ENVIRONMENT
		do
			if attached execution_environment.arguments.separate_character_option_value ('d') as l_dir then
				create l_env.make_with_directory_name (l_dir)
			else
				create l_env.make_default
			end
			create Result.make (l_env)
		end

feature -- CMS storage

	setup_storage (a_setup: CMS_SETUP)
		do
			a_setup.storage_drivers.force (create {CMS_STORAGE_SQLITE3_BUILDER}.make, "sqlite3")
--			a_setup.storage_drivers.force (create {CMS_STORAGE_STORE_MYSQL_BUILDER}.make, "mysql")
			a_setup.storage_drivers.force (create {CMS_STORAGE_STORE_ODBC_BUILDER}.make, "odbc")
		end

feature -- CMS modules

	setup_modules (a_setup: CMS_SETUP)
			-- Setup additional modules.
		local
			m: CMS_MODULE
		do
			create {CMS_ADMIN_MODULE} m.make
			a_setup.register_module (m)

				-- Auth
			create {CMS_AUTHENTICATION_MODULE} m.make
			a_setup.register_module (m)

			create {CMS_BASIC_AUTH_MODULE} m.make
			a_setup.register_module (m)

			create {CMS_OAUTH_20_MODULE} m.make
			a_setup.register_module (m)

			create {CMS_OPENID_MODULE} m.make
			a_setup.register_module (m)

				-- Nodes
			create {CMS_NODE_MODULE} m.make (a_setup)
			a_setup.register_module (m)

			create {CMS_BLOG_MODULE} m.make
			a_setup.register_module (m)

				-- Taxonomy
			create {CMS_TAXONOMY_MODULE} m.make
			a_setup.register_module (m)

				-- Recent changes
			create {CMS_RECENT_CHANGES_MODULE} m.make
			a_setup.register_module (m)

				-- Recent changes
			create {FEED_AGGREGATOR_MODULE} m.make
			a_setup.register_module (m)

				-- Miscellanious
			create {CMS_DEBUG_MODULE} m.make
			a_setup.register_module (m)

			create {CMS_DEMO_MODULE} m.make
			a_setup.register_module (m)

			create {GOOGLE_CUSTOM_SEARCH_MODULE} m.make
			a_setup.register_module (m)

			create {CMS_SESSION_AUTH_MODULE} m.make
			a_setup.register_module (m)

				-- uploader
			create {CMS_FILE_UPLOADER_MODULE} m.make
			a_setup.register_module (m)
		end

end
