
-- modified from 
-- https://dataedo.com/samples/html/World_PostgreSQL/doc/World_(PostgreSQL_database)_11/home.html

CREATE TABLE public.city (
    id          integer      NOT NULL,
    name        text         NOT NULL,
    countrycode character(3) NOT NULL,
    district    text         NOT NULL,
    population  integer      NOT NULL,
    CONSTRAINT city_pkey PRIMARY KEY (id)
);

CREATE TABLE public.country (
    code           character(3)  NOT NULL,
    name           text          NOT NULL,
    continent      text          NOT NULL,
    region         text          NOT NULL,
    surfacearea    real          NOT NULL,
    indepyear      smallint,
    population     integer       NOT NULL,
    lifeexpectancy real,
    gnp            numeric(10,2),
    gnpold         numeric(10,2),
    localname      text          NOT NULL,
    governmentform text          NOT NULL,
    headofstate    text,
    capital        integer,
    code2          character(2) NOT NULL,
    CONSTRAINT country_pkey            PRIMARY KEY (code),
    CONSTRAINT country_continent_check CHECK (((continent = 'Asia'::text) 
                                            OR (continent = 'Europe'::text) 
                                            OR (continent = 'North America'::text) 
                                            OR (continent = 'Africa'::text) 
                                            OR (continent = 'Oceania'::text) 
                                            OR (continent = 'Antarctica'::text) 
                                            OR (continent = 'South America'::text))),
    CONSTRAINT country_capital_fkey    FOREIGN KEY (capital) REFERENCES public.city(id)
);

CREATE TABLE public.countrylanguage (
    countrycode character(3) NOT NULL,
    language    text         NOT NULL,
    isofficial  boolean      NOT NULL,
    percentage  real         NOT NULL,
    CONSTRAINT countrylanguage_pkey PRIMARY KEY (countrycode, language),
    CONSTRAINT countrylanguage_countrycode_fkey FOREIGN KEY (countrycode) REFERENCES public.country(code)
);
