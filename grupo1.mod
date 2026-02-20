param H integer > 0; #Numero de Horas
param P integer > 0; #Numero de productos de un calibre fijo
param C integer > 0; #Numero de clientes
param E integer > 0; #Numero de estapas

set Horas = 0..H;
set Productos = 1..P;
set Etapas = 0..E;
set Clientes = 1..C;

param CantAcach integer > 0; #Numero de cantidad de alcachofas
param RatioMax {Productos,Etapas} >= 0; 
#Ratio maximo de cada etapa por cada producto
param DemandaMin {Productos,Clientes} >= 0; 
#Demanda mínima que solicita cada cliente de el producto
param DemandaMax {Productos,Clientes} >=0;
#Demanda maxima que solicita cada cliente de el producto
param Precio {Productos,Clientes} >= 0;
#Precio al que me compra el cliente cada producto

set EtapasFijas within Etapas;
set EtapasBinarias within Etapas;
set EtapasVariables within Etapas;
# Las estapas que son de mantenimiento Fijo ,Binario y Variable

param MantFijas {EtapasFijas};
param MantBinarias {Productos,EtapasBinarias};
param MantVariables {Productos,EtapasVariables};
#La cantidad de dinero que hay que gastar para el mantenimiento de las estapas

param CosteInicial {Etapas};
#La cantidad de dinero que hay que gastar para activar cada etapa

set Orden {Productos} within Etapas;
param Receta {Productos,Etapas} binary;
#El orden que sigue cada producto de las etapas y una matriz auxiliar binaria

var Cantidad {p in Productos,Orden[p],Horas} integer >= 0; 
#Cantidad de producto que ha pasado hasta cierta etapa en una hora indicada
var Ratio {Productos,Etapas,Horas}integer >=0;
#Cantidad que sale de la etapa
var Disponible{Productos};
var Vender {Productos,Clientes};
var Ocupado {Productos,Etapas,Horas};
var Encendido {Productos,Etapas,Horas};



