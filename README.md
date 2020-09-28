### Resumen

El presente trabajo hace un análisis no supervisado y supervisado de pacientes de la Unidad de Terapia Intensiva del Beth Israel Deaconess Medical Center de Boston ingresados entre 2001 y 2012, usando la información recopilada durante el primer día de internación. 
En primer lugar, se desarrolla un indicador de casos atípicos implementando las técnicas de Kurtosis plus Specific Directions y de Redes Neuronales Autoencoders.
En segundo lugar, se genera un predictor de mortalidad durante la primera semana ajustando un Modelo Aditivo Generalizado (GAM) con regularización. 
Por último, se evalúa la capacidad predictiva del indicador de atipicidad y del predictor GAM frente a tres scores de severidad estándar en unidades de terapia intensiva.

### Resumen extendido

El presente trabajo se propone hacer un análisis no supervisado y supervisado de pacientes de la Unidad de Terapia Intensiva del Beth Israel Deaconess Medical Center de Boston ingresados entre 2001 y 2012.

En lo que refiere al aprendizaje no supervisado, generamos un indicador de atipicidad o anomalía de los pacientes en términos de las mediciones fisiológicas y características físicas registradas durante las primeras 24 horas después de su ingreso. En particular, ajustamos dos indicadores usando las técnicas de Kurtosis plus Specific Directions (Peña y Prieto 2007) y de Autoencoder (Thompson etal. 2002). Estos indicadores podrían usarse en la práctica como insumo para tratar pacientes así como también para el desarrollo de investigaciones.

En cuanto al aprendizaje supervisado, generamos un predictor de mortalidad dentro de los 7 días posteriores a la internación usando como insumo los atributos de las primeras 24 horas usados para la tarea no supervisada. En particular, ajustamos un Modelo Aditivo Generalizado con penalización de tipo lasso (Chouldechova y Hastie 2015). La elección del modelo se debe a que permite captar no linealidaes y alcanzar mejor precisión en la clasificación que modelos más simples, a la vez que admite interpretar el impacto de los principales factores asociados a la mortalidad por separado, dada la aditividad del modelo. Asimismo, la regularización realiza selección automática de variables relevantes a la vez que trata la potencial multicolinealidad que trae aparejada el uso de atributos correlacionados.

El predictor GAM es validado mediante model stacking (ver sección 2.2.3.2) en una regresión logística junto al indicador de anomalía ajustado con el Autoencoder, y junto a tres predictores estándar de severidad que también usan información de las primeras 24 horas: SOFA (Vincent etal. 1996), SAPSII (Le Gall, Lemeshow, y Saulnier 1993) y OASIS (Johnson, Kramer, y Clifford 2013). El objetivo de esta etapa es evaluar la significatividad del aporte de ambos indicadores –el predictor de mortalidad y el indicador de atipicidad– a la predicción de mortalidad en la primera semana.

### Trabajo completo

Acceder al PDF [aquí](https://github.com/ftvalentini/mimic-mortality/blob/master/informe/valentini_especializacion_final.pdf).
