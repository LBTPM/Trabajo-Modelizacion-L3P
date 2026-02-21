param H integer > 0; #Numero de Horas

set HORAS ordered := 1..H;
set PRODUCTOS;
set CLIENTES;
set DIAS;
set ETAPAS ordered;
set ETAPASCOMPLETO ordered:= ETAPAS union {card(ETAPAS) + 1};

param CantAlcach {DIAS} integer > 0; #Numero de cantidad de alcachofas
param RatioMax {PRODUCTOS,ETAPAS} >= 0; 
#Ratio maximo de cada etapa por cada producto
param DemandaMin {PRODUCTOS,CLIENTES} >= 0; 
#Demanda mínima que solicita cada cliente de el producto
param DemandaMax {PRODUCTOS,CLIENTES} >=0;
#Demanda maxima que solicita cada cliente de el producto
param Precio {PRODUCTOS,CLIENTES} >= 0;
#Precio al que me compra el cliente cada producto
param FactorConversion {PRODUCTOS} >= 0;
#Factor de conversion de productos a alcachofas

param TipoEtapas {ETAPAS}; #Parametro que dice el tipo de las etapas

set EtapasFijas within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 1};
set EtapasBinarias within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 2};
set EtapasVariables within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 3};
# Las estapas que son de mantenimiento Fijo ,Binario y Variable

param MantFijas {EtapasFijas};
param MantBinarias {PRODUCTOS,EtapasBinarias};
param MantVariables {PRODUCTOS,EtapasVariables};
#La cantidad de dinero que hay que gastar para el mantenimiento de las estapas

param CosteInicial {ETAPAS};

set EtapasCoste within ETAPAS := {e in ETAPAS: CosteInicial[e] > 0};
#La cantidad de dinero que hay que gastar para activar cada etapa

param Receta {PRODUCTOS,ETAPAS};
set Orden {p in PRODUCTOS} within ETAPAS  ordered:= {e in ETAPAS: Receta[p,e] = 1};
set OrdenCompleto {p in PRODUCTOS}  ordered:= Orden[p] union {last(ETAPASCOMPLETO)};
#El orden que sigue cada producto de las etapas y una matriz auxiliar binaria

set OrdenInvs {e in ETAPAS} within PRODUCTOS := {p in PRODUCTOS: e in Orden[p]};
#Orden inverso

param SubProdNecesario{PRODUCTOS,ETAPAS} >=0; #Calculamos los factores de conversión para la cantidad y los ratios a partir de la cantidad de subproducto
param FactorConversion_ratio {p in PRODUCTOS,e in Orden[p]} := prod{f in Orden[p]: ord(e) <= ord(f)} SubProdNecesario[p,f];
param FactorConversion {p in PRODUCTOS} := FactorConversion_ratio[p,first(Orden[p])]; #Factor de conversion de productos a alcachofas

/*******************************************************************************************************/

var Cantidad {p in PRODUCTOS, OrdenCompleto[p], HORAS, g in DIAS} integer >= 0, <= CantAlcach[g]/FactorConversion[p]; 
#Cantidad de producto que esta esperando en cierta etapa a una hora dada un día determinado

var Ratio {p in PRODUCTOS,e in Orden[p],HORAS, DIAS}integer >=0, <=RatioMax[p,e];
#Cantidad de producto que procesa una etapa en una hora dada un día determinado

var Ocupado {p in PRODUCTOS,Orden[p],HORAS, DIAS} binary;
#1 si el producto dado esta en la etapa dada en la hora dada el día indicado

var Encendido {EtapasCoste,HORAS, DIAS} binary;
#1 si la etapa dada esta encendida en la hora dada el día indicado

var Vender {p in PRODUCTOS,c in CLIENTES} integer >= DemandaMin[p,c], <=DemandaMax[p,c];
#Cantidad de producto vendido a un cliente

/***************************************************************************************************/

maximize GanarDinero: 
    (sum{p in PRODUCTOS, c in CLIENTES} (Vender[p,c]*Precio[p,c])) 
    - (sum{e in EtapasFijas, g in DIAS} (CosteInicial[e]*card(HORAS)))
    - (sum {p in PRODUCTOS, g in DIAS} ((sum {e in (EtapasBinarias inter Orden[p])}(sum {h in HORAS} Ocupado[p,e,h,g]) * MantBinarias[p,e]) 
    - (sum {e in (EtapasVariables inter Orden[p])}(sum {h in HORAS} Ratio[p,e,h,g]) * MantVariables[p,e]))) 
    - (sum{e in EtapasCoste, h in HORAS, g in DIAS} Encendido[e,h,g]*CosteInicial[e]);
# Esta es nuestra función objetivo

/***************************************************************************************************/

subject to Cota_materia {g in DIAS}:
    sum{p in PRODUCTOS} Cantidad[p,first(Orden[p]),1,g]*FactorConversion[p] <= CantAlcach[g];
# Cantidad máxima de producto que se puede usar al día

subject to Final_es_inicial {p in PRODUCTOS, g in DIAS}:
    Cantidad[p,first(Orden[p]),1,g] = Cantidad[p,last(OrdenCompleto[p]),H,g];
# La cantidad de alcachofa producir ha de ser la misma cantidad para productos

subject to Inicializacion {p in PRODUCTOS, e in (OrdenCompleto[p] diff {first(Orden[p])}), g in DIAS}:
    Cantidad[p,e,1,g] = 0;
# Al comienzo del día las máquinas empiezan vacías

subject to Produccion_crear {p in PRODUCTOS, e in (Orden[p] diff {first(Orden[p])}), h in (HORAS diff {1}), g in DIAS}: 
    Cantidad[p,e,h,g] = Cantidad[p,e,h-1,g] - Ratio[p,e,h-1,g] + Ratio[p,prev(e,Orden[p]),h-1,g];
# Restricción que liga la cadena de producción y hace que no se cree producto en etapas intermedias

subject to Produccion_crear_final {p in PRODUCTOS, h in (HORAS diff {1}), g in DIAS}:
    Cantidad[p,last(ETAPASCOMPLETO),h,g] = Cantidad[p,last(ETAPASCOMPLETO),h-1,g] + Ratio[p,last(Orden[p]),h-1,g];
# Restricción que acumula al final de la cadena de producción todos los productos ya terminados cada día

subject to Produccion_crear_inicial {p in PRODUCTOS, h in (HORAS diff {1}),g in DIAS}:
    Cantidad[p,first(Orden[p]),h,g] = Cantidad[p,first(Orden[p]),h-1,g] - Ratio[p,first(Orden[p]),h-1, g];
# Restricción que va tomando las alcachofas al principio de la cadena para empezar a procesarlas por horas cada

subject to Producir_Posible {p in PRODUCTOS, e in Orden[p], h in HORAS, g in DIAS}:
    Ratio[p,e,h,g] <= Cantidad[p,e,h,g];
# El ratio de producción de una hora no puede ser más grande que
# la cantidad de productos que se tienen esperando en esa etapa

subject to Unicidad_producto {e in ETAPAS, h in HORAS, g in DIAS}:
    sum{p in OrdenInvs[e]} Ocupado[p,e,h,g] <= 1;
# Cada etapa solo puede estar trabajando un producto a la vez

subject to Cota_ratio {p in PRODUCTOS, e in Orden[p], h in HORAS, g in DIAS}:
    Ratio[p,e,h,g] <= Ocupado[p,e,h,g]*RatioMax[p,e];
# Si la máquina está encendida, el ratio no puede ser mayor que su máximo asociado
# a cada etapa en cada hora y para cada producto en cada día

subject to Encender_si_produciendo_ini {e in EtapasCoste, g in DIAS}:
    sum{p in OrdenInvs[e]} Ocupado[p,e,1,g] <= Encendido[e,1,g];
# Restricción que cuenta si la etapa inicial de cada producto ha pasado de inactiva a activa

subject to Encender_si_produciendo {e in EtapasCoste, h in (HORAS diff {1}), g in DIAS}:
    sum{p in OrdenInvs[e]} (Ocupado[p,e,h,g] - Ocupado[p,e,h-1,g]) <= Encendido[e,h,g];
# Restricción que cuenta si una etapa distinta de la primera acaba de empezar a producir

subject to Rest_venta {p in PRODUCTOS}:
    (sum{c in CLIENTES} Vender[p,c]) = (sum{g in DIAS} Cantidad[p,last(ETAPASCOMPLETO),H,g]);
# Restricción que vende todo el producto que se ha creado