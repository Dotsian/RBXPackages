--!strict

local ENFORCE_ERRORS = true

local Basics = require(script.Basics)
local Types = require(script.Types)

local Enforce = Basics.Enforce
local Extend = Basics.Extend

local Models = {
	_objects = {} :: { [string]: { Types.BaseModel } },
}

------------------------------------------------------------------------------------------------------------------------

-- Base class for all models.
function Models.BaseModel(): Types.BaseModel
	local self = {
		ID = 0,
		ExtraData = {},
		__name__ = "BaseModel",
		__properties__ = {},
	} :: Types.BaseModel

	function self:__register__()
		local Name: string? = debug.traceback("", 2):match("function ([^\n]+)")

		if not Name then
			error("Failed to fetch BaseModel name", 2)
		end

		self = self :: Types.BaseModel

		self.__name__ = Name

		if Models._objects[self.__name__] == nil then
			Models._objects[self.__name__] = {}
		end

		table.insert(Models._objects[self.__name__], self)

		self.ID = #Models._objects[self.__name__]

		return self
	end

	function self:Property(Name: string, Function: (...any) -> any)
		self.__properties__[Name] = Function
	end

	function self:Release()
		local Objects = Models._objects[self.__name__]

		table.remove(Objects, table.find(Objects, self))

		self:Destroy()
	end

	function self:Destroy()
		return
	end

	function self:__string__()
		return (self :: Types.BaseModel).__name__
	end

	setmetatable(self, {
		__index = function(self: Types.BaseModel, Key: string)
			local Property = self.__properties__[Key]

			if Property then
				return Property(self)
			end

			return rawget(self :: any, Key)
		end,

		__tostring = function(self: Types.BaseModel)
			return self:__string__()
		end,
	})

	return self
end

------------------------------------------------------------------------------------------------------------------------

--[[
Registers a dictionary of models.

<strong>Model</strong>:			The model dictionary you want to register from.
]]
function Models:Register(Model: { [string]: any })
	Enforce(Model, "Model", { "table" })

	for Key, Function in Model do
		if type(Function) ~= "function" then
			continue
		end

		Models[Key] = Function
	end

	return nil
end

--[[
Yields the current thread until the specified model is registered.

<strong>Model</strong>:			The model to wait for.
<strong>Timeout</strong>:		The number of seconds to wait for the model before returning <code>nil</code>.
]]
function Models:WaitForModel<M>(Model: Types.Typed<M> | string, Timeout: number?): Types.Typed<Types.BaseModel>
	Enforce(Model, "Model", { "string", "function" })
	Enforce(Timeout, "Timeout", { "number", "nil" })

	local StartTime = tick()
	local Warned = false

	if type(Model) == "function" then
		Model = debug.info(Model, "n")
	end

	Model = Model :: string

	while not Models[Model] do
		if Timeout and (tick() - StartTime) > Timeout then
			break
		end

		if not Timeout and (tick() - StartTime) > 5 and not Warned then
			warn(`Infinite yield possible on '{script.Name}:("{Model})'`)
			Warned = true
		end

		task.wait()
	end

	return Models[Model] :: M
end

--[[
Returns a table containing all initiated model instances of the specified model.

<strong>Model</strong>:			The model to return all instances of.
]]
function Models:All<M>(Model: Types.Typed<M>): { M }
	Enforce(Model, "Model", { "function" })

	return Models._objects[debug.info(Model, "n")] or {}
end

--[[
Returns a list of all values from a specific attribute for all instances of a model.

<strong>Model</strong>:				The model you want to extract the values from.
<strong>Attribute</strong>:			The attribute you want to return.
]]
function Models:Values<M>(Model: Types.Typed<M>, Attribute: string): { any }
	Enforce(Model, "Model", { "function" })
	Enforce(Attribute, "Attribute", { "string" })

	local ValuesList = {}

	for _, Object in (Models._objects[debug.info(Model, "n")] or {}) do
		table.insert(ValuesList, Object[Attribute])
	end

	return ValuesList
end

--[[
Creates a new model instance using keyword arguments.

<strong>Model</strong>:				The model you want to create.
<strong>Kwargs</strong>:			The arguments you want to unpack into the model's constructor.
<strong>Order</strong>: 			A list of values that should be inserted based on their position in the table.
]]
function Models:Dynamic<M>(Model: Types.Typed<M>, Kwargs: { [any]: any }, Order: { any }): M
	return Model(Models:Unpack(Kwargs, Order))
end

--[[
Unpacks a dictionary in the specified order.

<strong>Dictionary</strong>:		The dictionary you want to unpack.
<strong>Order</strong>: 			A list of values that should be unpacked based on their position in the table.
]]
function Models:Unpack(Dictionary: { [string]: any }, Order: { any }): ...any
	local Unpacked = {}

	for _, Key in ipairs(Order) do
		if not Dictionary[Key] then
			continue
		end

		table.insert(Unpacked, Dictionary[Key])
	end

	return table.unpack(Unpacked)
end

--[[
Helper function that checks if a model instance exists by its ID.

<strong>Model</strong>:				The model to search for an instance in.
<strong>ID</strong>:				The ID of the instance you're searching for.
]]
function Models:Exists<M>(Model: Types.Typed<M>, ID: number): boolean
	Enforce(Model, "Model", { "function" })
	Enforce(ID, "ID", { "number" })

	return Models:FromID(Model, ID) ~= nil
end

--[[
Returns a filtered table containing all initiated model instances of the specified model that pass the condition.

<strong>Model</strong>:				The model that will be filtered for instances.
<strong>Conditional</strong>:		The function to filter the instances by.
]]
function Models:Filter<M>(Model: Types.Typed<M>, Conditional: (M) -> boolean): { M }
	Enforce(Model, "Model", { "function" })
	Enforce(Conditional, "Conditional", { "function" })

	local Name = debug.info(Model, "n")
	local FilteredTable: { M } = {}

	local Bucket: { M } = Models._objects[Name]

	if not Bucket then
		if ENFORCE_ERRORS then
			error("Could not find any objects in " .. Name, 2)
		end

		return {}
	end

	for _, Object in Bucket do
		if not Conditional(Object) then
			continue
		end

		table.insert(FilteredTable, Object)
	end

	return FilteredTable
end

--[[
Returns a model instance by its ID.

<strong>Model</strong>:				The model to return an instance of.
<strong>ID</strong>:				The ID of the instance to return.
]]
function Models:FromID<M>(Model: Types.Typed<M>, ID: number): M?
	Enforce(Model, "Model", { "function" })
	Enforce(ID, "ID", { "number" })

	local Bucket = Models._objects[debug.info(Model, "n")]

	if not Bucket then
		return nil
	end

	for _, Object in pairs(Bucket) do
		if Object.ID ~= ID then
			continue
		end

		return Object
	end

	return nil
end

--[[
Returns a model instance by its attribute and value.

<strong>Model</strong>:				The model to return an instance of.
<strong>Attribute</strong>:			The attribute to search for.
<strong>Value</strong>:				The value of the attribute.
]]
function Models:Get<M>(Model: Types.Typed<M>, Attribute: string, Value: any): M?
	Enforce(Model, "Model", { "function" })
	Enforce(Attribute, "Attribute", { "string" })

	local Name = debug.info(Model, "n")
	local Bucket = Models._objects[Name]

	if not Bucket then
		return nil
	end

	local FoundObject = nil

	for _, Object in pairs(Bucket) do
		if (Object :: any)[Attribute] ~= Value then
			continue
		end

		if FoundObject then
			error(`Two or more {Name}s were found when invoking '{script.Name}:{debug.info(1, "n")}'`, 2)
		end

		FoundObject = Object
	end

	return FoundObject
end

--[[
Copies attributes from a model instance onto a dictionary and returns it.

<strong>Model</strong>:				The model instance you want to copy from.
<strong>Attributes</strong>:		A list of attributes you want to copy from the model instance.
]]
function Models:Copy(Model: Types.BaseModel, Attributes: { string }): { [string]: any }
	Enforce(Model, "Model", { "table" })
	Enforce(Model, "Attributes", { "table" })

	local Object: { [string]: any } = {}

	for _, Attribute in pairs(Attributes) do
		if string.find(Attribute, "__") then
			local Split = string.split(Attribute, "__")

			local Identifier = Split[2]

			if Object[Identifier] ~= nil then
				Identifier = Split[1] .. "_" .. Identifier
			end

			local Parent = (Model :: any)[Split[1]]

			Object[Identifier] = if type(Parent == "table") then Parent[Split[2]] else nil

			continue
		end

		Object[Attribute] = (Model :: any)[Attribute]
	end

	return Object
end

------------------------------------------------------------------------------------------------------------------------

return Models



