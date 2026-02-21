param H integer > 0; #Numero de Horas

set HORAS ordered := 1..H;
set PRODUCTOS;
set CLIENTES;
set ETAPAS ordered;
set ETAPASCOMPLETO ordered:= ETAPAS union {card(ETAPAS) + 1};

param CantAlcach integer > 0; #Numero de cantidad de alcachofas
param RatioMax {PRODUCTOS,ETAPAS} >= 0; #Ratio maximo de cada etapa por cada producto
param DemandaMin {PRODUCTOS,CLIENTES} >= 0; #Demanda mínima que solicita cada cliente de el producto
param DemandaMax {PRODUCTOS,CLIENTES} >=0; #Demanda maxima que solicita cada cliente de el producto
param Precio {PRODUCTOS,CLIENTES} >= 0; #Precio al que me compra el cliente cada producto
param FactorConversion {PRODUCTOS} >= 0; #Factor de conversion de productos a alcachofas

param TipoEtapas {ETAPAS}; #Parametro que dice el tipo de las etapas

# Las estapas que son de mantenimiento Fijo ,Binario y Variable
set EtapasFijas within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 1};
set EtapasBinarias within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 2};
set EtapasVariables within ETAPAS := {e in ETAPAS: TipoEtapas[e] = 3};

#La cantidad de dinero que hay que gastar para el mantenimiento de las estapas
param MantFijas {EtapasFijas};
param MantBinarias {PRODUCTOS,EtapasBinarias};
param MantVariables {PRODUCTOS,EtapasVariables};


param CosteInicial {ETAPAS};

#La cantidad de dinero que hay que gastar para activar cada etapa
set EtapasCoste within ETAPAS := {e in ETAPAS: CosteInicial[e] > 0};

#El orden que sigue cada producto de las etapas y una matriz auxiliar binaria
param Receta {PRODUCTOS,ETAPAS};
set Orden {p in PRODUCTOS} within ETAPAS  ordered:= {e in ETAPAS: Receta[p,e] = 1};
set OrdenCompleto {p in PRODUCTOS}  ordered:= Orden[p] union {last(ETAPASCOMPLETO)};

#Orden inverso
set OrdenInvs {e in ETAPAS} within PRODUCTOS := {p in PRODUCTOS: e in Orden[p]};

var Cantidad {p in PRODUCTOS, OrdenCompleto[p], HORAS} integer >= 0, <= CantAlcach/FactorConversion[p]; #Cantidad de producto que esta esperando en cierta etapa a una hora dada
var Ratio {p in PRODUCTOS,e in Orden[p],HORAS}integer >=0, <=RatioMax[p,e]; #Cantidad de producto que procesa una etapa en una hora dada
var Ocupado {p in PRODUCTOS,Orden[p],HORAS} binary; #1 si el producto dado esta en la etapa dada en la hora dada
var Encendido {EtapasCoste,HORAS} binary; #1 si la etapa dada esta produciendo en la hora dada
var Vender {p in PRODUCTOS,c in CLIENTES} integer >=DemandaMin[p,c], <=DemandaMax[p,c]; #Cantidad de producto vendido a un cliente

maximize GanarDinero: 
    sum{p in PRODUCTOS, c in CLIENTES} Vender[p,c]*Precio[p,c] 
    - sum{e in EtapasFijas} MantFijas[e]*H 
    - sum {p in PRODUCTOS} (sum {e in (EtapasBinarias inter Orden[p] )}(sum {h in HORAS} Ocupado[p,e,h]) * MantBinarias[p,e] 
    - sum {e in (EtapasVariables inter Orden[p])}(sum {h in HORAS} Ratio[p,e,h]) * MantVariables[p,e]) 
    - sum{e in EtapasCoste, h in HORAS} Encendido[e,h]*CosteInicial[e];

subject to Cota_materia: 
    sum{p in PRODUCTOS} Cantidad[p,first(Orden[p]),1]*FactorConversion[p] <= CantAlcach;

subject to Final_es_inicial {p in PRODUCTOS}: 
    Cantidad[p,first(Orden[p]),1] = Cantidad[p,last(OrdenCompleto[p]),H];

subject to Inicializacion {p in PRODUCTOS, e in (OrdenCompleto[p] diff {first(Orden[p])})}:
    Cantidad[p,e,1] = 0;

subject to Produccion_crear {p in PRODUCTOS, e in (Orden[p] diff {first(Orden[p])}), h in (HORAS diff {1})}:
    Cantidad[p,e,h] = Cantidad[p,e,h-1] - Ratio[p,e,h-1] + Ratio[p,prev(e, Orden[p]),h-1];

subject to Produccion_crear_final {p in PRODUCTOS, h in (HORAS diff {1})}: 
    Cantidad[p,last(ETAPASCOMPLETO),h] = Cantidad[p,last(ETAPASCOMPLETO),h-1] + Ratio[p,last(Orden[p]),h-1];

subject to Produccion_crear_inicial {p in PRODUCTOS, h in (HORAS diff {1})}: 
    Cantidad[p,first(Orden[p]),h] = Cantidad[p,first(Orden[p]),h-1] - Ratio[p,first(Orden[p]),h-1];

subject to Producir_Posible {p in PRODUCTOS, e in Orden[p], h in HORAS}: 
    Ratio[p,e,h] <= Cantidad[p,e,h];

subject to Unicidad_producto {e in ETAPAS, h in HORAS}: 
    sum{p in OrdenInvs[e]} Ocupado[p,e,h] <= 1;

subject to Cota_ratio {p in PRODUCTOS, e in Orden[p], h in HORAS}: 
    Ratio[p,e,h] <= Ocupado[p,e,h]*RatioMax[p,e];

subject to Encender_si_produciendo_ini {e in EtapasCoste}: 
    sum{p in OrdenInvs[e]} Ocupado[p,e,1] <= Encendido[e,1];

subject to Encender_si_produciendo {e in EtapasCoste, h in (HORAS diff {1})}: 
    sum{p in OrdenInvs[e]} (Ocupado[p,e,h] - Ocupado[p,e,h-1]) <= Encendido[e,h];

subject to Rest_venta {p in PRODUCTOS}: 
    sum{c in CLIENTES} Vender[p,c] = Cantidad[p,last(ETAPASCOMPLETO),H];