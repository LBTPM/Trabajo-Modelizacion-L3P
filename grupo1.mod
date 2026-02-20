param H integer > 0; #Numero de Horas

set HORAS ordered := 1..H;
set PRODUCTOS;
set CLIENTES;
set ETAPAS ordered;
set ETAPASCOMPLETO := ETAPAS union {card(ETAPAS) + 1};

param CantAlcach integer > 0; #Numero de cantidad de alcachofas
param RatioMax {PRODUCTOS,ETAPAS} >= 0; 
#Ratio maximo de cada etapa por cada producto
param DemandaMin {PRODUCTOS,CLIENTES} >= 0; 
#Demanda mínima que solicita cada cliente de el producto
param DemandaMax {PRODUCTOS,CLIENTES} >=0;
#Demanda maxima que solicita cada cliente de el producto
param Precio {PRODUCTOS,CLIENTES} >= 0;
#Precio al que me compra el cliente cada producto

param TipoEtapas {ETAPAS}; #Parametro que dice el tipo de las etapas

set EtapasFijas within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 1};
set EtapasBinarias within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 2};
set EtapasVariables within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 3};
# Las estapas que son de mantenimiento Fijo ,Binario y Variable

param MantFijas {EtapasFijas};
param MantBinarias {PRODUCTOS,EtapasBinarias};
param MantVariables {PRODUCTOS,EtapasVariables};
#La cantidad de dinero que hay que gastar para el mantenimiento de las estapas

param CosteInicio {ETAPAS};

set EtapasCoste within ETAPAS := {e in ETAPAS: CosteInicio[e] > 0};
#La cantidad de dinero que hay que gastar para activar cada etapa

param Receta {PRODUCTOS,ETAPAS};
set Orden {p in PRODUCTOS} within ETAPAS := {e in ETAPAS: Receta[p,e] = 1} union {0};
#El orden que sigue cada producto de las etapas y una matriz auxiliar binaria

var Cantidad {p in PRODUCTOS,Orden[p] diff {0},HORAS} integer >= 0; 
#Cantidad de producto que esta esperando en cierta etapa a una hora dada
var Ratio {PRODUCTOS,ETAPAS,HORAS}integer >=0;
#Cantidad de producto que procesa una etapa en una hora dada
var Vender {PRODUCTOS,CLIENTES};
#Cantidad de producto vendido a un cliente
var Ocupado {PRODUCTOS,ETAPAS,HORAS} binary;
#1 si el producto dado esta en la etapa dada en la hora dada
var Encendido {ETAPAS,HORAS} binary;
#1 si la etapa dada esta produciendo en la hora dada

param Ingresos := sum{p in PRODUCTOS, c in CLIENTES} Vender[p,c]*Precio[p,c];
param Mantenimiento := sum {p in PRODUCTOS} (sum {e in EtapasBinarias}(sum {h in HORAS} Ocupado[p,e,h]) * MantBinarias[p,e] + sum {e in EtapasVariables}(sum {h in HORAS} Ratio[p,e,h]) * EtapasVariables[p,e]);
param CosteInicio := sum{e in EtapasCoste, h in HORAS} Encendido[e,h]*CosteInicial[e];

maximize GanarDinero: Ingresos - Mantenimiento - CosteInicio;

subject to 