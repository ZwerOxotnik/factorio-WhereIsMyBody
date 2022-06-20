
local settings = {
	{type = "int-setting", name = "WHMB_update_tick", setting_type = "runtime-global", default_value = 120, minimum_value = 1, maximum_value = 8e4},
	{type = "double-setting", name = "WHMB_line_width", setting_type = "runtime-per-user", default_value = 0.2, minimum_value = 0.1, maximum_value = 20},
	{type = "bool-setting", name = "WHMB_create_lines", setting_type = "runtime-per-user", default_value = true}
}

if ZKSettings then
	for _, setting in pairs(settings) do
		ZKSettings.create_setting(setting.name, setting.type, setting.setting_type, setting.default_value, setting) -- welp it looks awful
	end
else
	data:extend(settings)
end
