/*

Cleaning the Nashville Housing Data using SQL

*/


--First lets get idea of what we have in our data


SELECT * 
FROM PortfolioProject..NashvilleHousing;

-------------------------------------------------------

-- Standardize Date Format: SaleDate field in data contains the time as well, which is irrelevant here so we need to convert from date-time format to just date format

-- First, lets look at how our converted sale date format looks like compared to original column sale date
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM PortfolioProject..NashvilleHousing;

--Above query looks good, now lets add a column "SaleDateConverted" and then update it using the CONVERT function
ALTER TABLE PortfolioProject..NashvilleHousing
ADD  SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate)


-----------------------------------------------

-- Populate Property Address Data


--First Checking the Nulls, and finding the parameter which we can use to populate these Null fields
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL;

--We find that when ParcelID fields are same the Housing addresses are same, We confirm this using below query 
SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;

-- Using self Join to see into the same table with same parcel IDs but not same addresses
SELECT *
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]

-- using the ISNULL function to populate empty property addresses
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


-- Above query gives desired results so now lets update our database
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL AND b.PropertyAddress IS NOT NULL;



-----------------------------------------------------------------------------------------------------------


--Breaking out Address into individual columns (Address, city, state)


SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;

-- Using the SUBSTRING and CHARINDEX functions
SELECT
SUBSTRING(Propertyaddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
SUBSTRING(Propertyaddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address2
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
ADD  PropertySplitAddress NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(Propertyaddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD  PropertySplitCity NVARCHAR(255);

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(Propertyaddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID;


----------------------------------------------------------------------------------------------


--Change Y and N to Yes and No in "Sold as Vacant" Field 


--Using below query we see that there were 4 fields Yes, No, Y, N. We need to put it in a standard Yes & No formats
SELECT DISTINCT (SoldasVacant)
FROM PortfolioProject..NashvilleHousing;
 
SELECT DISTINCT (SoldAsVacant), COUNT(SoldasVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- using the case to find Y and fill it with Yes and N for No
SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
END AS NewSoldAsVacant
FROM PortfolioProject..NashvilleHousing;


-- Above query gives desired results, so now lets update the database
UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
END 

--We confirm again
SELECT DISTINCT (SoldasVacant)
FROM PortfolioProject..NashvilleHousing;

------------------------------------------------------------------------------------

--Remove Duplicates

WITH rownumCTE AS (
	SELECT *, ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
					 UniqueID
					 ) row_num

FROM PortfolioProject..NashvilleHousing
)

SELECT * 
FROM rownumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

SELECT *
FROM PortfolioProject..NashvilleHousing;

----------------------------------------------------------------------------------------------

--Delete Unused Columns: There are some unused columns which can be dropped without any concerns

SELECT * 
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, Saledate
