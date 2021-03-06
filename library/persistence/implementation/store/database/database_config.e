﻿note
	description: "Database configuration"
	date: "$Date: 2014-08-20 15:21:15 -0300 (mi., 20 ago. 2014) $"
	revision: "$Revision: 95678 $"

deferred class
	DATABASE_CONFIG

feature -- Database access

	default_hostname: STRING = ""
			-- Database hostname.

	default_username: STRING = ""
			-- Database username.

	default_password: STRING = ""
			-- Database password.

	default_database_name: STRING = "EiffelDB"
			-- Database name.

	is_keep_connection: BOOLEAN
			-- Keep Connection to database?
		do
			Result := True
		end

end
