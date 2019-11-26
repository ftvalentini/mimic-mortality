-- correr desde SQL shell (enter with parametros de 00-connection.r)

set search_path to mimiciii;

-- needed views
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/echo-data.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/durations/ventilation-durations.sql;

-- firstday stats
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/blood-gas-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/blood-gas-first-day-arterial.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/gcs-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/labs-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/rrt-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/urine-output-first-day.sql;
--\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/vitals-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/postgresql/vitals-first-day-FV.sql;

\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/weight-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/height-first-day.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/firstday/ventilation-first-day.sql;

-- severity scores
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/severityscores/sofa.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/severityscores/sapsii.sql;
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/severityscores/oasis.sql;

-- sepsis (martin definition)
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/sepsis/martin.sql;

-- diagnoses
\cd C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/diagnosis
\i C:/Users/Fran/Documents/MaestriaDM/trabajo_esp/mimic/resources/external/mimic-code/concepts/diagnosis/ccs_diagnosis_table.sql;

