---
title: Bienvenide a nidi.to
---

La guía no-definitiva sobre la red casera.

## TL;DR;

- Todos los dispositivos que se conecten a la red deben ser actualizados tan pronto como sea posible
- Todo lo que pueda usar una contraseña o pin, debe de tener una configurada y distinta entre sí
- [1Password](https://1password.com) o [LastPass](https://www.lastpass.com/password-manager) son la onda
- En caso de duda, pregúntale a roberto qué pedo

## No mames roberto, neta tengo que leer esto?

Pues estas son las únicas buenas noticias, en realidad ¡te puede valer queso (casi) todo lo que viene en este documento! La postura bajo la cual desarrollé estos lineamientos es aquella de "[cero confianza](https://en.wikipedia.org/wiki/Zero_Trust_Networks)", lo cual quiere decir que roberto _confía_ que hay dispositivos inseguros, jaqueados, malvibrosos o de plano con ganas de joder dentro de la red, y por lo tanto existen medidas de seguridad para proteger los **datos que le importan a roberto**.

La idea de este documento es que no sólo los dispositivos y datos de roberto estén protegidos, sino también de quienes hagamos uso de la red casera. Las computadoras, en general, son tremendamente inseguras dada su naturaleza interconectada, y roberto pretende enumerar las prácticas de seguridad que considera mínimas para prevenir que tus datos y dispositivos caigan en manos de un [script kiddie](https://en.wikipedia.org/wiki/Script_kiddie) en busca de bitcoin.


## Bueno, y ¿de qué va, o qué?

Primero vamos a presentarte las capas de nuestra red casera. Hay un montón de aparatos, cables y pendejadas, y creo que es útil definirles. Por otro lado, la red casera tiene una capa tecno-social, es decir, nuestro comportamiento humano relacionado a esta bola de aparatejos. Después, vamos a hablar de los retos a los que nos enfrentamos al compartir esta red casera, y cuáles son las prácticas que roberto considera útiles para dormir tranquilo.

### De qué _no_ va

Hay ciertos temas que son importantes, pero de los que no vamos a hablar en este documento.

- respaldos (dos, mínimo: uno en la nube, otro local)
- protección ante los recursos de una nación-estado (si una de esas quiere joder, va a joder, y es no resulta práctico defenderse por defenderse 😭)
- seguridad/privacidad en la chamba (dispositivos y redes distintas para casa y chamba; no usar cuentas personales en cosas de la chamba)

## Capa física

La red casera está compuesta de varios dispositivos, entre ellos:

- Módem: es el dispositivo que realiza la conexión entre la red pública (el internet, el internet, [el internet](https://www.youtube.com/watch?v=LybAHotsvOg)) y nuestra red interna. Este dispositivo es propiedad del proveedor de servicios y jamás se debe compartir con nadie ningún dato relacionado al mismo, incluyendo contraseñas, modelo, ni número de serie (salvo con el proveedor de servicios). Asumimos que este dispositivo es muy inseguro, pues el proveedor de servicios puede cambiar su configuración de manera remota. Además del cable de corriente eléctrica, el cable de fibra que venga de la calle (opcionalmente, de un conversor entre el cable de fibra gruesa exterior, al mono-hilo de fibra interior). En caso de emergencia informática, o falla del servicio de internet, el paso uno es **desconectar esto de la corriente eléctrica**.
- Router: es un dispositivo encargado de filtrar los datos que fluyen dentro, fuera, y entre los dispositivos de la red (comúnmente conocido como "firewall"). Además, se asegura de [multiplexar y demultiplexar](https://es.wikipedia.org/wiki/Multiplexaci%C3%B3n) (combinar y separar) las distintas señales de los dispositivos conectados a la red. No se debe conectar ningún dispositivo al router ni cambiar las conexiones que ya existen.
- Punto de acceso inalámbrico (AP, de _access point_ por sus siglas en inglés): el güai-fai, pues. En casa, este radio nos permite conectar nuestros dispositivos personales a la red. Presenta varias señales, una para cada tipo de "usuario" (humanos y robots, en general)
- "robotitos": En casa tenemos varios dispositivos conectados a la red que son más "electrodomésticos" que "computadoras personales", por ejemplo: Apple TV, Nintendo Switch, aire acondicionado, o cualquier mamada que se pueda considerar como "el internet de las cosas"... Estos dispositivos son increíblemente inseguros, pues son administrados remotamente por el fabricante y roberto no puede hacer mucho para prevenir que cualquier jaquer de dos pesos los ponga a robarnos datos (en el mejor de los casos).
- servidores: Denominamos "servidor" a aquellas computadoras que están conectadas y operando continuamente sin interrupciones. Estas computadoras pueden ser de uso general (es decir, hacen de chile, mole y pozole) o de uso específico (cómo un servidor de almacenamiento), y corren software como "servidores web" para prestar servicios a las computadoras personales de la red.

La mayor parte de los dispositivos descritos aquí están conectados a la red eléctrica mediante un UPS (_Uninterruptible power supply_) que se encarga de entregar y regular la corriente eléctrica en caso de "picos" y falla de la red eléctrica. Nuestra red casera, incluyendo la mayoría de los "robotitos", no consumen más de 100 watts/hora (es decir, menos que un foco incandescente), y todos ellos (módem, router, AP, robotitos y servidores) son administrados y configurados por roberto; no es necesario que te preocupes por su configuración!

---

Por otro lado, la idea de una red casera es poder dar servicio a "computadoras personales": tu compu, mi compu, la compu de nuestras visitas, la computadora con teléfono de tu bolsillo (también tiene un módem!), tu DSLR con wi-fi, y la tablet que usas para leer las noticias en el baño. En general, roberto no puede/quiere/debe configurar ni operar estos dispositivos, y es responsabilidad personal mantenerles en buen estado.

Ciertamente hay computadoras en otros dispositivos que no se conectan a la red casera, pero roberto no es suficientemente paranoico para intentar protegerse de alguien con la capacidad y ganas de joder a través de estos vectores.

## Capa tecno-social

Pues bueno, en nuestra red casera existen muchos datos. Hay unos bien útiles (cómo tus estados de cuenta bancarios) o irremplazables (como fotos de tu primera comunión), y hay unos que realmente no importa perder (el caché temporal de tus descargas de spotify). Hay datos personales (que no son del interés colectivo, como tus cartitas de amorrrrr), y datos compartidos (cómo la contraseña de una red inalámbrica). Mediante el uso consciente de los recursos de la red casera, podemos ayudar a prevenir que estos datos sean expuestos indiscriminadamente o que aquellos datos inútiles nos agobien.

Por otro lado, nuestro comportamiento y uso de la red debe mantenerse tan privado como cada usuario desee (es decir, pon en instagram lo que te de la gana). No queremos que nuestro proveedor de servicio sepa qué series vemos, ni la legalidad de nuestro acceso a las mismas. Bajo el yugo del capital es imposible escapar del constante monitoreo; roberto, por ejemplo, firma contratos de confidencialidad con los dueños de sus quincenas y permite que administren su computadora de manera remota, pero desea mantener el resto de las actividades de la red fuera del alcance de su empleador.

Además, estamos quienes usamos la red casera, con necesidades distintas y cambiantes. La idea de operar una red casera es a


## Los retos

Nuestra red aplica distintas estrategias para facilitar la privacidad de sus usuarios, ajustarse a las necesidades cambiantes, y prevenir que los jaquers hagan su desmadre, y cuándo lo hagan sea el menor posible.

### Los cambios a la red se platican

Pues eso, yo nomás opero la red por qué me gusta, pero los cambios a la red se platican para darle buen servicio a todos los dispositivos que la usen. Aunque contenga multitudes, roberto el técnico operador de la red es un pinche huevón y el único que se rifa a operar la red, por lo tanto, la red casera está planeada para que no le tenga que llamar seguido a roberto el técnico, y sus horarios de operación programada son de lunes a viernes 10pm a 2am, y 2pm a 2am sábados y domingos. Casi no la cago, pero suele suceder, me da por experimentar y se me queman las tortillas, mismos horarios. Idealmente, sabrás con dos horas de anticipación use la red como juguete, y salvo emergencias, no habrá cambios a la red durante horas decentes de trabajo (9am-8pm).

### VLANs

Virtual Local Area Network, por sus siglas en inglés. En pocas palabras, el "router" se encarga de aislar el tráfico entre redes por omisión. Los "robotitos" son a mi modo de ver el vector más probable de ser jaquiado, así que viven en su propia red (`robotitos` y `robotitos_lts`) para que una vez truenen, no tengan acceso a nuestros "servidores" ni dispositivos personales; estos últimos tienen su propia red, llamada `📡`. Por último, los "servidores" tienen su propia red `␖/␆`.

### Firewall

Un programa del router que filtra y re-direcciona los paquetes que desean intercambiar los dispositivos. Disminuye los vectores de ataque que un dispositivo jaquiado puede usar para joder en otros dispositivos de la red. Por cuestiones de privacidad, no se lleva registro de ningún paquete de la red `📡`, y roberto promete avisar con al menos dos horas de anticipación en caso de habilitar el registro de paquetes para diagnosticar problemas en la red.

### DNS

Domain Name System, por sus siglas en inglés. El servicio de DNS es el que "traduce" entre nombres de dominio (`google.com`) y direcciones IP (`142.250.81.78`), las cuales son usadas por los dispositivos al enviar paquetes por la red. En nuestra red hay distintos servidores que ofrecen el servicio de DNS por tres motivos:

- ofrecer servicios bajo el dominio `nidi.to`, por ejemplo: `radio.nidi.to`,
- ofrecer el servicio de ["Hoyo negro de DNS"](https://es.wikipedia.org/wiki/Sumidero_de_DNS), (tipo bloqueo de anuncios, y más, pero sin tener que instalar nada), y
- ofrecer una alternativa al servicio de DNS del proveedor de servicio, que no tengo que leer sus términos de uso pa saber que van a darle uso malvibroso (por ejemplo, mostrar anuncios).

Por lo tanto, el "router" y uno de nuestros "servidores" ofrecen dos servicios de DNS.

1. El primero es usado por omisión al conectarse a cualquier red, y no registra ningún dominio público. Está disponible en `10.20.0.1`.
2. El segundo servicio ofrece bloqueo de anuncios, el cual además de lo obvio, ayuda a limitar el tráfico dentro y fuera de la red; este servicio está disponible en `10.10.0.2` y `10.10.0.3`, y **lleva registros de uso por dispositivo** (dominio visitado/hora/dispositivo) los cuales son eliminados cada 7 días. La neta no los reviso tan seguido como debería (nomás pa darme color a tiempo cuando algún "robotito" sea jaquiado).

## Tú merol

Bueno, pues usted, persona leyendo este documento, forma parte de las estrategias que usamos para mantener bien portada nuestra red. Más o menos en orden de importancia, esto es lo que debemos hacer:


### Actualizar dispositivos

Mantener actualizados a las últimas versiones (estables, no _beta_) disponibles todos nuestros dispositivos que se conecten a la red, y todas sus aplicaciones, según sea el caso. Teléfono, computadora, extensor de red, bocinas inteligentes, refrigeradores, microondas, estufas, lavadoras, o algo de fierro nuevo "inteligente" que esté a la venta.

Es buena idea habilitar las actualizaciones automáticas en todos los dispositivos, salvo en computadoras. Estos son los lineamientos que roberto usa para decidir cuándo actualizar su computadora y aplicaciones esenciales (aquellas sin las cuales no puedo chambear o pagar cuentas, por ejemplo):

- espero entre un mes y una semana antes de instalar actualizaciones "mayores". Las actualizaciones "mayores" son aquellas en las cuales cambia el número más significativo de una versión, por ejemplo de la versión `10.15.7` a `11.1`. Es buena idea preguntar a usuarios de los mismos sistemas/aplicaciones sobre su experiencia al actualizar, y roberto también hace paro si tienes dudas en cuanto al tiempo que es prudente esperar.
- para actualizaciones "menores" o "parches" (en las cuales cambian los demás dígitos) la neta casi no la pienso, pero a veces me meto a ver reseñas o de plano me espero una semana.
- no instalo versiones de prueba, _beta_, o de procedencia dudosa, de las herramientas que más me importan estén disponibles sí o sí. 9 de cada 10 veces todo sale bien, pero esa 1 que no arde un chingo.
- en cosas tipo "robotitos", se actualiza tan pronto sea posible, y a lo mucho una vez a la semana

A través de esta práctica le das chance a quienes desarrollan los sistemas operativos y aplicaciones de tus dispositivos de corregir nuestros errores. Es un dicho popular de la industria que "debuggear es la acción de encontrar y desarticular 'bugs' en un programa, y por lo tanto programar es la práctica de idearlos e introducirlos al código". roberto cree que una gran parte de los vectores de ataque que pueden afectar redes casera como la nuestra, se pueden prevenir al actualizar constantemente nuestros dispositivos personales.

> Oye roberto, y qué pedo con todas las mamadas que describiste allá arriba? esos cómo se actualizan? — Tan pronto existe una actualización de sistema operativo, en los horarios descritos allá arriba. Los servicios de la red se actualizan dos veces al mes, maomenos.

### Credenciales, credenciales, credenciales

Usa contraseñas diferentes para cada cosa, idealmente contraseñas generadas al azar, de más de 32 caracteres y procura cambiar las más importantes en caso de que cualquiera de ellas fuese comprometida.

Contraseñas importantes como:

- correo
- apple id / google coso android?
- cuenta de celular
- imss/sat/etc
- asuntos financieros (banco/tarjeta/inversión/seguros)

Para hacerte la vida más fácil existen aplicaciones para administrar credenciales, las cuales se encargan de generar contraseñas suficientemente seguras a la vez que te permiten sólo recordar (idealmente) una contraseña. roberto usa [1Password](https://1password.com), pero también existe [LastPass](https://www.lastpass.com/password-manager), y en el ecosistema de apple iCloud tiene también el "keychain". La ventaja de usar una contraseña única para cada cosa es que cuando jaquieen un servicio y se vuelen tu dirección de correo y, en el peor de los casos, tu contraseña para ese servicio, no puedan entrar con los mismos datos a tu correo, o solicitar tokens de tu banco.

Tus dispositivos también deben contar con un pin o contraseña, e idealmente deben bloquearse y requerir que se ingresen de nuevo las credenciales a los 5 minutos, o menos. Esto ayuda a prevenir que un jaquer dentro de nuestro espacio físico pueda hacer de las suyas en nuestros dispositivos o el resto de la red.

### En caso de duda

Mantener una red segura no es necesariamente fácil, hay cosas que requieren adaptar hábitos y tomar pausas para validar lo que está pasando. Para los casos en los que no sea claro el camino más seguro, pues para eso está roberto. No se las sabe todas, pero te asiste buscándole y preguntándole a su comunidad ñoña.
