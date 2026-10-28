# Objetivo / implementado / Flutter

33 operaciones objetivo. Jobs futuras conservadas como x-target-responses, no éxitos reales. Diferencias de schemas: ProspectingJobDetail. Requests diferentes: GET /api/v1/prospecting-jobs.

GET Jobs: el contrato objetivo usa SortBy genérico; la implementación y Flutter limitan a createdAt,updatedAt,startedAt,completedAt,status,id. El detalle efectivo siempre entrega resultsAvailable=false y results/progress=null; la copia Flutter documenta esa disponibilidad. Las diferencias JSON no se interpretan como FAIL de producto sin contraste con código/Swagger.
