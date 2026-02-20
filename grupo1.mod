param H integer > 0; #Numero de Horas

set Horas ordered := 1..H;
set Productos;
set Clientes;
set Etapas;


param CantAlcach integer > 0; #Numero de cantidad de alcachofas
param RatioMax {Productos,Etapas} >= 0; 
#Ratio maximo de cada etapa por cada producto
param DemandaMin {Productos,Clientes} >= 0; 
#Demanda mínima que solicita cada cliente de el producto
param DemandaMax {Productos,Clientes} >=0;
#Demanda maxima que solicita cada cliente de el producto
param Precio {Productos,Clientes} >= 0;
#Precio al que me compra el cliente cada producto

param TipoEtapas {Etapas}; #Parametro que dice el tipo de las etapas

set EtapasFijas within Etapas := {e in Etapas: TipoEtapas[e] = 1};
set EtapasBinarias within Etapas := {e in Etapas: TipoEtapas[e] = 2};
set EtapasVariables within Etapas := {e in Etapas: TipoEtapas[e] = 3};
# Las estapas que son de mantenimiento Fijo ,Binario y Variable

param MantFijas {EtapasFijas};
param MantBinarias {Productos,EtapasBinarias};
param MantVariables {Productos,EtapasVariables};
#La cantidad de dinero que hay que gastar para el mantenimiento de las estapas

param CosteInicial {Etapas};

set EtapasCoste within Etapas := {e in Etapas: CosteInicial[e] > 0};
#La cantidad de dinero que hay que gastar para activar cada etapa

param Receta {Productos,Etapas} binary;
set Orden {Productos} within Etapas := {};
#El orden que sigue cada producto de las etapas y una matriz auxiliar binaria

var Cantidad {p in Productos,Orden[p],Horas} integer >= 0; 
#Cantidad de producto que ha pasado hasta cierta etapa en una hora indicada
var Ratio {Productos,Etapas,Horas}integer >=0;
#Cantidad que sale de la etapa
var Disponible{Productos};
var Vender {Productos,Clientes};
var Ocupado {Productos,Etapas,Horas};
var Encendido {Productos,Etapas,Horas};



