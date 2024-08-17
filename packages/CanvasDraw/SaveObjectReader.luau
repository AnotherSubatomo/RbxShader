--!native

local SaveObjReader = {}

local HttpService = game:GetService("HttpService")

local StringCompressor = require(script.Parent:WaitForChild("StringCompressor"))

function SaveObjReader.Read(SaveObject)
	local CompressedRGB = SaveObject:GetAttribute("Colour")
	local CompressedAlpha = SaveObject:GetAttribute("Alpha")
	local Resolution = SaveObject:GetAttribute("Resolution")
	local Width, Height = Resolution.X, Resolution.Y

	-- Decompress the data
	local RGBArray = HttpService:JSONDecode(StringCompressor.Decompress(CompressedRGB))
	local AlphaArray = HttpService:JSONDecode(StringCompressor.Decompress(CompressedAlpha))
	
	local PixelArray = table.create(Width * Height * 4)
	
	for i = 1, Width * Height do
		local RGBIndex = i * 3 - 2
		local RGBAIndex = i * 4 - 3

		PixelArray[RGBAIndex] = RGBArray[RGBIndex] / 255
		PixelArray[RGBAIndex + 1] = RGBArray[RGBIndex + 1] / 255
		PixelArray[RGBAIndex + 2] = RGBArray[RGBIndex + 2] / 255
		PixelArray[RGBAIndex + 3] = AlphaArray[i] / 255
	end

	return PixelArray, Width, Height
end

function SaveObjReader.ReadLegacy(SaveObject)
	local SaveDataImageColours = SaveObject:GetAttribute("ImageColours")
	local SaveDataImageAlphas = SaveObject:GetAttribute("ImageAlphas")
	local SaveDataImageResolution = SaveObject:GetAttribute("ImageResolution")

	-- Decompress the data
	local DecompressedSaveDataImageColours = StringCompressor.Decompress(SaveDataImageColours)
	local DecompressedSaveDataImageAlphas = StringCompressor.Decompress(SaveDataImageAlphas)

	-- Get a single pixel colour info form the data
	local PixelDataColoursString = string.split(DecompressedSaveDataImageColours, "S")
	local PixelDataAlphasString = string.split(DecompressedSaveDataImageAlphas, "S")

	local PixelArray = {} -- {r, g, b, a, r, g, b, a...}

	for i, PixelColourString in pairs(PixelDataColoursString) do
		local RGBValues = string.split(PixelColourString, ",")
		local R, G, B = table.unpack(RGBValues)

		local PixelAlpha = tonumber(PixelDataAlphasString[i])

		local Index = i * 4 - 3

		PixelArray[Index] = R / 255
		PixelArray[Index + 1] = G / 255
		PixelArray[Index + 2] = B / 255
		PixelArray[Index + 3] = PixelAlpha / 255
	end
	
	return PixelArray, SaveDataImageResolution.X, SaveDataImageResolution.Y
end

return SaveObjReader
