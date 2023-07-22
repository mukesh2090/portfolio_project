use portfolio_project_covid19
go

select *
from CovidDeaths

select *
from [dbo].[CovidVaccinations]

select location,date,total_cases,new_cases,total_deaths,population
from CovidDeaths
order by 1,2

--Looking at total_cases vs total_death
--shows likelyhood of dying if you contract covid in your country

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Death_percentage
from CovidDeaths
where location like 'ind%'
order by 1,2

--looking at total_cases vs total_population
--shows what percentage of population got covid
select location,date,population,total_cases,(total_cases/population)*100 as percentage_population_affected
from CovidDeaths
--where location like 'ind%'
order by 1,2

--looking at countries with highest infection rate compared to population
select location,population,max(total_cases) as highest_infection_count,max((total_cases/population))*100 as percentage_population_affected
from CovidDeaths
--where location like 'ind%'
--and continent is not null
group by location,population
order by percentage_population_affected desc

--showing countries with highest death count per population

select location,max(cast(Total_deaths as int)) as total_death_count
from CovidDeaths
--where location like 'ind%'
where continent is not null
group by location
order by total_death_count desc

--Lets break things down by continent

select continent,max(cast(Total_deaths as int)) as total_death_count
from CovidDeaths
--where location like 'ind%'
where continent is not null
group by continent
order by total_death_count desc

--global_numbers

select date,sum(new_cases) as total_cases,sum(cast(new_deaths as int))as total_deaths, SUM(CAST(new_deaths as int))/ sum(new_cases)*100 as death_percentage_global
from CovidDeaths
where continent is not null
group by date
order by 1,2

--looking at total_population vs total_vaccinations

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as rolling_people_vaccinated
from CovidDeaths  dea
join CovidVaccinations  vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3
--using cte
with popvsvac (continent,location,date,population,new_vaccinations,rolling_people_vaccinated)
as
(
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as rolling_people_vaccinated
from CovidDeaths  dea
join CovidVaccinations  vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(rolling_people_vaccinated/population)*100
from popvsvac

--temp_table
DROP Table if exists #percent_people_vaccinated
Create Table #percent_people_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #percent_people_vaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as rolling_people_vaccinated
from CovidDeaths  dea
join CovidVaccinations  vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
--order by 2,3
Select *, (RollingPeopleVaccinated/Population)*100
From #percent_people_vaccinated

-- Creating View to store data for later visualizations

Create View percent_people_vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 