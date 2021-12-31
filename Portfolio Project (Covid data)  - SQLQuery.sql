--USE [Portfolio Project]
--GO

--SELECT  * 
--FROM CovidDeaths;


--SELECT * 
--FROM CovidVaccinations
--ORDER BY 3,4;

-- Choosing the main fields in the CovidDeaths table as below:

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total Cases VS Total Deaths related to Covid for each Country as per Month, Year

SELECT location, DATENAME(month,date) AS Month, year(date) AS Year, 
       COUNT(total_cases) AS TotalCovidCases,
       COUNT(total_deaths) AS TotalPeopleDied 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,DATENAME(month,date), year(date)
ORDER BY year(date);

-- Total Cases vs Total Deaths in Year 2020, 2021 in different locations across the world
SELECT location, year(date) AS Year, 
       COUNT(total_cases) AS TotalCovidCases,
       COUNT(total_deaths) AS TotalPeopleDied 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, year(date)
ORDER BY location, year(date);

-- Total Cases vs Total Deaths to calculate Death percentage at different locations across the world


SELECT location, Date, population, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, Date;

-- Checking the Death Percentage from Covid for Australia
SELECT location, Date, population,  Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Australia' AND continent IS NOT NULL;       --- From Jan 1, 2020 to end Feb 2020 Australia had a few Covid cases less than 30, 0% death rate

--- Checking the Death Percentage for any country (Using LIKE operator)

SELECT location, Date, population, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND location LIKE '%a';  -- any location ending with 'a'

SELECT location, Date, population, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
WHERE location LIKE 'i%i_' AND continent IS NOT NULL;   -- location = 'India'

-- Percentage of total people in Australia who contracted Covid-19
SELECT location, Date, population AS Population, Total_Cases, (Total_Cases/population)*100 AS ContractedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL AND location LIKE 'Aust%ia';  -- any location ending with 'a'

-- %People contracted Covid worldwide 
SELECT location, Date, population AS Population, Total_Cases, (Total_Cases/population)*100 AS ContractedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
order by 1,2; 

-- Looking at Countries with the highest Covid Infections (population contracted)

SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestInfectedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
ORDER BY HighestInfectedPercentage DESC;

-- Calculating Death Count for countries - Highest death count per Population

-- SELECT location, MAX(total_deaths) AS HighestDeathCount  -- total_deaths in nvarchar(255)

SELECT location, MAX(CONVERT(int,total_deaths)) AS HighestDeathCount  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;

--OR--

SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC;


---Checking this query for a location say United States

SELECT max(total_cases), MAX(CAST(total_deaths AS int))
FROM CovidDeaths
Where location = 'United States' AND continent IS NOT NULL
GROUP BY location;
-- https://www.worldometers.info/coronavirus/country/us/   -- RESULTS nearly match

---Checking this query for a location say Australia

SELECT max(total_cases), MAX(CAST(total_deaths AS int))
FROM CovidDeaths
Where location = 'Australia' AND continent is NULL
GROUP BY location;
- https://www.worldometers.info/coronavirus/country/us/   -- Results alomost match again (Verifying the results of my query with real-time numbers)

-- Covid results by Continent (Highest DeathCount by Continent)

SELECT continent, MAX(CAST(total_deaths AS int)) AS HighestDeathCount  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathCount DESC;


--- Highest Death Count by population for continent

SELECT continent,population, MAX(CAST(total_deaths AS int)) AS HighestDeathCount  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY HighestDeathCount DESC;



-- Global Numbers for Covid Pandemic from the  start date till date (start of the pandemic till date in the whole world)

SELECT SUM(CAST(new_deaths AS int)) AS Total_Deaths, SUM(new_cases) AS Total_Covid_Cases, 
      (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
-- ORDER BY  date;

--- Total population and its vaccination rates

SELECT  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
        SUM(CAST(CV.new_vaccinations AS int)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		-- SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
FROM CovidDeaths CD
INNER JOIN CovidVaccinations  CV
ON CD.location = CV.location  AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 
ORDER BY 2,3;

-- To calculate - %age of Population in each location is vaccinated 


-- Method 1: Using CTE

WITH PopVac (Continent, location, date, population, new_vaccinations, RollingVaccinationNumbers)
AS
(
SELECT  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
        SUM(CAST(CV.new_vaccinations AS int)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		-- SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		--(RollingVaccinationNumbers/Population)*100 AS PercentageTotalPopulationVaccinated

FROM CovidDeaths CD
INNER JOIN CovidVaccinations  CV
ON CD.location = CV.location  AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3
)

SELECT *, (RollingVaccinationNumbers/Population)*100 AS PercentageTotalPopulationVaccinated
FROM PopVac;

--METHOD 2: TEMP TABLE

DROP TABLE if exists #PercentagePopsVac

CREATE TABLE #PercentagePopsVac
(
 Continent nvarchar(255),
 location nvarchar(255),
 date DATETIME,
 population numeric,
 new_vaccinations numeric,
 RollingVaccinationNumbers numeric
 )
 

INSERT INTO #PercentagePopsVac
SELECT  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
        SUM(CAST(CV.new_vaccinations AS Decimal(18,2))) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		-- SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		--(RollingVaccinationNumbers/Population)*100 AS PercentageTotalPopulationVaccinated

FROM CovidDeaths CD
INNER JOIN CovidVaccinations  CV
ON CD.location = CV.location  AND CD.date = CV.date
-- WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3


SELECT *, (RollingVaccinationNumbers/Population)*100 AS PercentageTotalPopulationVaccinated
FROM #PercentagePopsVac;

--- Creating a few Important Views to store data to use for creating visualizations

-- View for PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated as
SELECT  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
        SUM(CAST(CV.new_vaccinations AS Decimal(18,2))) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		-- SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		--(RollingVaccinationNumbers/Population)*100 AS PercentageTotalPopulationVaccinated
FROM CovidDeaths CD
INNER JOIN CovidVaccinations  CV
ON CD.location = CV.location  AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
-- ORDER BY 2,3

--View for HighestDeathCount

CREATE VIEW HighestDeathCount as
SELECT continent,population, MAX(CAST(total_deaths AS int)) AS HighestDeathCount  
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
--ORDER BY HighestDeathCount DESC;

--View for GlobalCovidFigures
CREATE VIEW GlobalCovidNumbers as
SELECT SUM(CAST(new_deaths AS int)) AS Total_Deaths, SUM(new_cases) AS Total_Covid_Cases, 
      (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
-- ORDER BY  date;



-- Total Cases vs Total Deaths in Year 2020, 2021 in different locations across the world
CREATE VIEW CasesvsDeaths as
SELECT location, year(date) AS Year, 
       COUNT(total_cases) AS TotalCovidCases,
       COUNT(total_deaths) AS TotalPeopleDied 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, year(date)
--ORDER BY location, year(date);

-- Total Cases vs Total Deaths to calculate Death percentage at different locations across the world

CREATE VIEW DeathPecentage as
SELECT location, Date, population, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--ORDER BY location, Date;


-- %People contracted Covid worldwide 

CREATE VIEW PercentPeopleContractedCovid as 
SELECT location, Date, population AS Population, Total_Cases, (Total_Cases/population)*100 AS ContractedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--order by 1,2; 

-- Looking at Countries with the highest Covid Infections (population contracted)

CREATE VIEW HighlyInfectedLocations as
SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestInfectedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
--ORDER BY HighestInfectedPercentage DESC;

CREATE VIEW RollingVaccinationNumbers as
SELECT  CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
        SUM(CAST(CV.new_vaccinations AS int)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
		-- SUM(CONVERT(int, CV.new_vaccinations)) OVER (Partition By CD.location ORDER BY CD.location, CD.date) AS RollingVaccinationNumbers
FROM CovidDeaths CD
INNER JOIN CovidVaccinations  CV
ON CD.location = CV.location  AND CD.date = CV.date
WHERE CD.continent IS NOT NULL 
--ORDER BY 2,3;






































