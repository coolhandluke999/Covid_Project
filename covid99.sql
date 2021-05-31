SELECT *
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT *
--FROM [dbo].[covid_vaccinations]
--ORDER BY 3, 4

--Select Data that we are going to use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..covid_deaths
ORDER BY 1, 2

--Total Case vs Total Deaths
	--% chance of dying if you contract Covid
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidProject..covid_deaths
WHERE location LIKE '%states%'
ORDER BY 1, 2 DESC

--Continent Total DeathPercentage


--Total Cases vs Population
	--% of population that got Covid
SELECT location, date, population, total_cases, (total_cases / population) * 100 AS CasesPercentofPop
FROM CovidProject..covid_deaths
WHERE location LIKE '%states%'
ORDER BY 1, 2

-- Identify countries with highest infection rate (total_cases / population)
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidProject..covid_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Continent by infection rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM CovidProject..covid_deaths
WHERE continent IS NULL
GROUP BY location, population 
ORDER BY PercentPopulationInfected DESC

-- Countries with highest Death Count per Population

SELECT location, population, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

--Grouped by continent
SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM CovidProject..covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--Continents with highest death count
SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Worldwide Total

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as INT)) AS total_deaths, SUM(CAST(new_deaths as INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

--Worldwide by Date

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as INT)) AS total_deaths, SUM(CAST(new_deaths as INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2 

--Join death and vaccination tables
SELECT *
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Global vaccinations vs population

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3 

--Add column that is a sum of previous days new_vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_sum_vacs,
		MAX(
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND new_vaccinations IS NOT NULL
ORDER BY 2,3 

--USE CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_sum_vacs)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_sum_vacs		
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)

SELECT *, (rolling_sum_vacs / population) * 100 AS vac_rate_pop
FROM pop_vs_vac

--Temp table

DROP TABLE IF EXISTS #Percent_Pop_Vaccinated
CREATE TABLE #Percent_Pop_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_sum_vacs numeric
)

INSERT INTO #Percent_Pop_Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_sum_vacs		
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 

SELECT *, (rolling_sum_vacs / population) * 100 AS vac_rate_pop
FROM #Percent_Pop_Vaccinated

# Create View

--Worldwide

CREATE VIEW Percent_Pop_Vaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_sum_vacs		
FROM CovidProject..covid_deaths AS dea
JOIN CovidProject..covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2, 3

SELECT *
FROM Percent_Pop_Vaccinated
