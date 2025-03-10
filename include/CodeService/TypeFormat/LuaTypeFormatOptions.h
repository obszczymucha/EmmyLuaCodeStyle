#pragma once

#include <map>
#include <string>

class LuaTypeFormatOptions
{
public:
	static LuaTypeFormatOptions ParseFrom(std::map<std::string, std::string, std::less<>>& stringOptions);

	bool format_line = true;
	bool auto_complete_end = true;
	bool auto_complete_table_sep = true;
};
