package hx.well.config;

/**
 * Database connection configuration type definition
 * Used to describe connection parameters for different database drivers
 */
typedef ConnectionTypedef = {
	/** Database driver name */
	var driver:ConnectionDriver;

	/** Database name, used for MySQL target */
	var ?database:String;

	/** Database socket path, used for MySQL target */
	var ?socket:String;

	/** Database file path, used for file-based databases, used for SQLite target */
	var ?path:String;

	/** Database host address */
	var ?host:String;

	/** Database port number */
	var ?port:Int;

	/** Database username */
	var ?username:String;

	/** Database password */
	var ?password:String;
}

enum abstract ConnectionDriver(String) to String from String {
	/**
	 *  MySQL driver name 
	 */
	var MYSQL = "mysql";

	/** 
	 * SQLite driver name 
	 */
	var SQLITE = "sqlite";

	/**
	 * No driver
	 */
	var NONE = "none";
}
