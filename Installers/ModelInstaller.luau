local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local Files = {"Models.luau", "Basics.luau", "Types.luau"}

function FetchFile(Path: string): string?
	local URL = "https://raw.githubusercontent.com/Dotsian/RBXPackages/main/Models/"..Path

	local Success, Result = pcall(function()
		return HttpService:GetAsync(URL)
	end)

	if not Success then
		warn("[Installer]: Failed to fetch contents for "..Path, Result)
		return nil
	end

	return Result
end

for _, InstallFile in Files do
	local Source = FetchFile(InstallFile)

	if not Source then
		return
	end

	local Module = Instance.new("ModuleScript")
	Module.Name = string.split(InstallFile, ".")[1]
	Module.Source = Source

	Module.Parent = if InstallFile == "Models.luau" then ServerScriptService else ServerScriptService.Models

	if InstallFile == "Models.luau" then
		Selection:Set({Module})
	end

	print("[Installer]: Installed "..InstallFile.."!")
end

print("[Installer]: Installation complete!")

