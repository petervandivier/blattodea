
-- modified from 
-- https://dataedo.com/samples/html/World_PostgreSQL/doc/World_(PostgreSQL_database)_11/home.html

CREATE TABLE city (
    id          integer      NOT NULL,
    name        text         NOT NULL,
    country_code character(3) NOT NULL,
    district    text         NOT NULL,
    population  integer      NOT NULL,
    CONSTRAINT city_pkey PRIMARY KEY (id)
);

CREATE TABLE country (
    code             character(3)  NOT NULL,
    name             text          NOT NULL,
    continent        text          NOT NULL,
    region           text          NOT NULL,
    surface_area     real          NOT NULL,
    indep_year       smallint,
    population       integer       NOT NULL,
    life_expectancy  real,
    gnp              numeric(10,2),
    gnp_old          numeric(10,2),
    local_name       text          NOT NULL,
    government_form  text          NOT NULL,
    head_of_state    text,
    capital          integer,
    code2            character(2) NOT NULL,
    CONSTRAINT country_pkey            PRIMARY KEY (code),
    CONSTRAINT country_continent_check CHECK (((continent = 'Asia'::text) 
                                            OR (continent = 'Europe'::text) 
                                            OR (continent = 'North America'::text) 
                                            OR (continent = 'Africa'::text) 
                                            OR (continent = 'Oceania'::text) 
                                            OR (continent = 'Antarctica'::text) 
                                            OR (continent = 'South America'::text))),
    CONSTRAINT country_capital_fkey    FOREIGN KEY (capital) REFERENCES city(id)
);

CREATE TABLE countrylanguage (
    country_code character(3) NOT NULL,
    language     text         NOT NULL,
    is_official  boolean      NOT NULL,
    percentage   real         NOT NULL,
    CONSTRAINT countrylanguage_pkey PRIMARY KEY (country_code, language),
    CONSTRAINT countrylanguage_countrycode_fkey FOREIGN KEY (country_code) REFERENCES country(code)
);
