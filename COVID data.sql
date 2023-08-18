--Displaying the data of the deaths through COVID
SELECT *
FROM PortfolioProject..CovidDeath

--Displaying the data of the vaccinations of COVID
SELECT *
FROM PortfolioProject..CovidVaccinations

--Calculating the Death percentage showing the chances of an individual
SELECT Location, date, total_deaths, total_cases, 
    CASE 
        WHEN TRY_CAST(total_deaths AS float) IS NOT NULL AND TRY_CAST(total_cases AS float) IS NOT NULL AND TRY_CAST(total_cases AS float) <> 0 
            THEN (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100
        ELSE NULL
    END AS DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE Location LIKE 'INDIA'

--Calculating the infect percentage to the know about the percentage of population getting infected by COVID
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectPercentage
FROM PortfolioProject..CovidDeath
WHERE Location LIKE 'INDIA'


--Getting the state with highest InfectRatio
SELECT Location,  MAX(total_cases) AS HighestInfectionCount, population, MAX((total_cases/population))*100 AS InfectPercentage
FROM PortfolioProject..CovidDeath
GROUP BY location, population
ORDER BY InfectPercentage DESC

--Countries with Highest Death Count per population
SELECT Location,  MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Getting Continents ordered by Highest Death Count per population
SELECT continent,  MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC

--Getting the number of cases turning up onn day basis
SELECT 
    date, 
    SUM(new_cases) AS "Total Cases", 
    SUM(CAST(new_deaths as int)) AS "Total Deaths", 
    CASE 
        WHEN SUM(new_cases) <> 0 
            THEN (SUM(CAST(new_deaths as int)) / NULLIF(SUM(new_cases), 0)) * 100
        ELSE NULL
    END AS "Death Ratio"
FROM PortfolioProject..CovidDeath
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Knowing the overall Death Ratio
SELECT
    SUM(new_cases) AS "Total Cases", 
    SUM(CAST(new_deaths as int)) AS "Total Deaths", 
    CASE 
        WHEN SUM(new_cases) <> 0 
            THEN (SUM(CAST(new_deaths as int)) / NULLIF(SUM(new_cases), 0)) * 100
        ELSE NULL
    END AS "Death Ratio"
FROM PortfolioProject..CovidDeath
WHERE continent is not null
ORDER BY 1,2



--Joining the tables CovidDeath and CovidVaccinations based on the location and date
SELECT *
FROM PortfolioProject..CovidDeath death
JOIN PortfolioProject..CovidVaccinations vaccine
ON death.location=vaccine.location and death.date=vaccine.date

--Getting the number of vaccinations done in various continents on day basis
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER (PARTITION BY death.Location ORDER BY death.Location, death.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeath death
JOIN PortfolioProject..CovidVaccinations vaccine
	ON death.location=vaccine.location and death.date=vaccine.date
WHERE death.continent is not null
ORDER BY 2,3

--Converting the above query to CTE
WITH PopulationVSVaccination (Continent, Location, Date, Population, NewVaccinations, TotalPeopleVaccinated) AS (
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER (PARTITION BY death.Location ORDER BY death.Location, death.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeath death
JOIN PortfolioProject..CovidVaccinations vaccine
	ON death.location=vaccine.location and death.date=vaccine.date
WHERE death.continent is not null
)

--Displaying the data using CTE
--Knowing individual continent Rolling vaccination percentage
SELECT * , ((TotalPeopleVaccinated)/Population)*100 AS IndTotalVaccination
FROM PopulationVSVaccination



-- TEMP Table
DROP Table IF EXISTS #PercentageOfPopulationVaccinated
CREATE TABLE #PercentageOfPopulationVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPepleVaccinated numeric
)

INSERT INTO #PercentageOfPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER (PARTITION BY death.Location ORDER BY death.Location, death.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeath death
JOIN PortfolioProject..CovidVaccinations vaccine
	ON death.location=vaccine.location and death.date=vaccine.date
WHERE death.continent is not null


--Creation of a view
CREATE VIEW PopulationVaccinated AS (
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CONVERT(bigint, vaccine.new_vaccinations)) OVER (PARTITION BY death.Location ORDER BY death.Location, death.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidDeath death
JOIN PortfolioProject..CovidVaccinations vaccine
	ON death.location=vaccine.location and death.date=vaccine.date
WHERE death.continent is not null
)