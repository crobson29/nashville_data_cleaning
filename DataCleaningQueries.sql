
SELECT *
FROM NashvilleDataCleaning..NashvilleHousing

------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

SELECT SaleDateConverted
FROM NashvilleDataCleaning..NashvilleHousing

ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleDataCleaning..NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)


-----------------------------------------------------------------------------------------------------------------------------------------
--Populate Property Address Data

SELECT *
FROM NashvilleDataCleaning..NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

--The ParcelID and the PropertyAddress are linked, and are the same for every instance.  The uniqueID is the differentiator;


--Used to find points where property address is null, checks for uniqueness by the uniqueID is different;
--Run after the update to check if it worked properly
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleDataCleaning..NashvilleHousing a
JOIN NashvilleDataCleaning..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--Update the table to fill the null property address instances.
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleDataCleaning..NashvilleHousing a
JOIN NashvilleDataCleaning..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------------------------
--Breaking Address into seperate columns for address, city, and state

--Start with PropertyAddress
SELECT PropertyAddress
FROM NashvilleDataCleaning..NashvilleHousing
--After checking the data with the above query, it is known that the only delimiter is a comma

SELECT
--SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
--, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, CHARINDEX(',', PropertyAddress)) as City        <- This would occasionally cut off the last letter of the city, the below query works perfectly
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM NashvilleDataCleaning..NashvilleHousing

--Creating the new columns for the separated data
ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleDataCleaning..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleDataCleaning..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM NashvilleDataCleaning..NashvilleHousing

--Now for the OwnerAddress

SELECT OwnerAddress
FROM NashvilleDataCleaning..NashvilleHousing

--Using a different method this time
SELECT
PARSENAME(REPLACE(OwnerAddress,',', '.'),3) as Address
, PARSENAME(REPLACE(OwnerAddress,',', '.'),2) as City
, PARSENAME(REPLACE(OwnerAddress,',', '.'),1) as State
FROM NashvilleDataCleaning..NashvilleHousing


ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleDataCleaning..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'),3)

UPDATE NashvilleDataCleaning..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'),2)

UPDATE NashvilleDataCleaning..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'),1)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Standardize the answers in the Sold as Vacant field

SELECT DISTINCT(SoldAsVacant) , COUNT(SoldAsVacant)
FROM NashvilleDataCleaning..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--Since Yes and No are used far more often in the table, I will convert the y and n values to yes and no

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleDataCleaning..NashvilleHousing


UPDATE NashvilleDataCleaning..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY uniqueID
					) row_num
FROM NashvilleDataCleaning..NashvilleHousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Now Delete the duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY uniqueID
					) row_num
FROM NashvilleDataCleaning..NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Delete Unused columns

ALTER TABLE NashvilleDataCleaning..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

SELECT *
FROM NashvilleDataCleaning..NashvilleHousing