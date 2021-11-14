/* 
COVID 19 Data exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


--Having a look at the 2 tables 
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4 ;


SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4 ;

-- Select data we are going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2 ;

-- Looking at Total Cases vs Total Deaths
-- Below Query shows the likelyhood of death if you contract covid in India
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2 ;

-- Looking at Total Cases vs Population  
-- Below query will show what percentage of population has been infected with covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CovidPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location = 'India'
ORDER BY 1,2 ;

-- Country with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_deaths/total_cases))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents by highest death count order
SELECT continent, MAX(CAST (total_deaths AS INT) ) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS
-- Each Day, total across the world
SELECT date, SUM (new_cases) AS Total_Cases, SUM (CAST (new_deaths AS INT)) AS Total_Deaths, SUM (CAST(new_deaths AS INT))/SUM (new_cases) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1;

-- Global Death Percentage
SELECT SUM (new_cases) AS Total_Cases, SUM (CAST (new_deaths AS INT)) AS Total_Deaths, SUM (CAST(new_deaths AS INT))/SUM (new_cases) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1;


-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM  PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- Looking at total population vs vaccinations with rolling count of New vaccinations #2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))  OVER (PARTITION BY  dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;



-- Use CTE (Common Table Expressions) to temporarily reference the tables
WITH PopvsVac (continent, location, date, population, New_Vaccination, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))  OVER (PARTITION BY  dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVaccinated
FROM PopvsVac


-- Temp Table (Name of the temp table should start with #)
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))  OVER (PARTITION BY  dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVaccinated
FROM #PercentPopulationVaccinated



-- CREATE VIEWS To store data for later visualizations(Its a virtual table based on the result set of an SQL statement)
CREATE VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT))  OVER (PARTITION BY  dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
;         


SELECT * FROM PercentPopulationVaccinated;