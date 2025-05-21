-- *PAÍSES*
-- RÁCIO DE MORTES POR CASO EM PORTUGAL
SELECT 
		location, 
		date, 
		COALESCE(total_cases, '-') total_cases, 
		COALESCE(total_deaths, '-') total_deaths,
		ROUND((CAST(total_deaths AS FLOAT)/total_cases) * 100, 2) DeathPercentage
FROM portfolio_project_covid..CovidDeaths
WHERE location LIKE '%Portugal%' AND continent IS NOT NULL 
ORDER BY 1,2;

-- RÁCIO DE CASOS POR POPULAÇÃO
SELECT location, 
	   date, 
	   population,
	   COALESCE(total_cases, '-') total_cases, 
	   ROUND((CAST(total_cases AS FLOAT)/population) * 100, 2) CasePercentage
FROM portfolio_project_covid..CovidDeaths;

-- PAÍSES COM MAIOR RÁCIO DE CASOS POR POPULAÇÃO
SELECT location, 
	   population, 
	   MAX(total_cases) HighestInfectionCount,  
	   ROUND(MAX((total_cases/population)) * 100, 2) PercentPopulationInfected
FROM portfolio_project_covid..CovidDeaths
--WHERE location LIKE '%Angola%'
GROUP BY location, population
ORDER BY 4 DESC;


-- *NÚMEROS GLOBAIS*
-- Nº DE MORTES POR CONTINENTE
SELECT continent, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM portfolio_project_covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

-- TOTAL PERCENTUAL DE MORTES POR CASOS
SELECT SUM(new_cases) total_cases, 
	   SUM(CAST(new_deaths AS INT)) total_deaths, 
	   ROUND(SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100, 2) DeathPercentage
FROM portfolio_project_covid..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL 
ORDER BY 1,2;

-- PERCENTAGEM DE POPULAÇÃO QUE TEM PELO MENOS UMA VACINA
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
	   --, (RollingPeopleVaccinated / population) * 100
FROM portfolio_project_covid..CovidDeaths dea
JOIN portfolio_project_covid..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USANDO CTE PARA REALIZAR CÁLCULOS NA QUERY ANTIGA
WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM portfolio_project_covid..CovidDeaths dea
JOIN portfolio_project_covid..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2, 3
)
SELECT *, ROUND((RollingPeopleVaccinated / Population) * 100, 2) PercentagePeopleperPopulation
FROM Pop_vs_Vac;

-- USANDO TEMP TABLE PARA REALIZAR CÁLCULOS
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM portfolio_project_covid..CovidDeaths dea
JOIN portfolio_project_covid..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated

-- CRIANDO VIEW DA QUERY PASSADA
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) RollingPeopleVaccinated
FROM portfolio_project_covid..CovidDeaths dea
JOIN portfolio_project_covid..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
