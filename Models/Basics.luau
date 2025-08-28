--!strict

return {
	Extend = function<T, U>(BaseClass: () -> T, NewClass: U): T & U
		local NewConstructor: any = {}

		for key, value in pairs(BaseClass()) do
			NewConstructor[key] = value
		end

		for key, value in pairs(NewClass) do
			NewConstructor[key] = value
		end

		return NewConstructor :: T & U
	end,

	Enforce = function(Variable: any, Name: string, Types: { string })
		if table.find(Types, typeof(Variable)) then
			return
		end

		local TypeList = Types[1]

		if #Types == 2 then
			TypeList = Types[1] .. " or " .. Types[2]
		end

		if #Types > 2 then
			local FullList = ""

			for Index, Type in Types do
				if Index == #Types then
					FullList = FullList .. "or " .. Type
					continue
				end

				FullList = FullList .. Type .. ", "
			end

			TypeList = FullList
		end

		error(Name .. " must be " .. TypeList .. ", not " .. typeof(Variable), 3)
	end,
}
