--!strict

--- Misc Type Definitions ---

export type TemplateGroup = "Basic" | "Advanced" | "Extreme" -- This is a template type, you can remove this.

--- Model Type Definitions ---

export type Template = BaseModel & { -- This is a template type, you can remove this.
	Name: string,
	Group: TemplateGroup,
}

--- Core Type Definitions ---

export type BaseModel = {
	ID: number,
	ExtraData: { any }?,

	__name__: string,
	__properties__: { [string]: Typed<any> },

	-- Registers a model instance by assigning it a name, ID, and inserting it into the model's object table.
	__register__: typeof(function<M>(_: M)
		local Model: M
		return Model
	end),

	-- Returns whenever the model instance is converted to string.
	__string__: typeof(function()
		local String: string
		return String
	end),

	-- Registers a new `Property` from a function.
	Property: typeof(function(_: BaseModel, Name: string, Function: Typed<any>) end),

	-- Custom function invoked after `Release()`.
	Destroy: typeof(function(_: BaseModel) end),

	-- Removes a model instance from the model's object table.
	Release: typeof(function(_: BaseModel) end),
}

export type Typed<T> = (...any) -> T

--- Module EOL ---

return nil
