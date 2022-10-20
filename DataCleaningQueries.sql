
SELECT *
FROM NashvilleDataCleaning..NashvilleHousing


-- Standardize Date Format

SELECT SaleDateConverted
FROM NashvilleDataCleaning..NashvilleHousing

ALTER TABLE NashvilleDataCleaning..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleDataCleaning..NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)



--Populate Property Address Data

SELECT *
FROM NashvilleDataCleaning..NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleDataCleaning..NashvilleHousing a
JOIN NashvilleDataCleaning..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null
