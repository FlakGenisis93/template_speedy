#ifndef __LASER_H__
#define __LASER_H__
//	D	E	F	I	N	E	S
#define IOWR_LASER_COMMAND(base, data)       				alt_write_word(base, data) //Schreiben an Laser Befehlsnummer
#define IOWR_LASER_ADDR(base, data)						alt_write_word(base + REG_W_ZELLE , data); //Schreiben von Speicheradresse
#define IOWR_LASER_INIT(base, data)						alt_write_word(base + REG_W_INIT , data); //Schreiben von Reset des Speichers


#define IORD_LASER_MEMORY(base)       				alt_read_word( base + REG_R_CHAR)//Lesen von Laser Char
#define IORD_LASER_COMMAND(base)					alt_read_word( base + REG_R_BEFEHL);//Lesen des aktuwellen wertes im Befehlsregister
#define IORD_LASER_ADDR(base)						alt_read_word( base + REG_R_ADDR)//Aktuelle Adresse lesen
#define IORD_LASER_INIT(base)						alt_read_word( base + REG_R_INIT)//Lesen ob der Speicher gerade zurueckgesetzt wird


#define REG_W_BEFEHL	( 0x0 )
#define REG_W_ZELLE		( 0x1 )
#define REG_W_INIT		( 0x2 )

#define REG_R_CHAR		( 0x0 )
#define REG_R_BEFEHL	( 0x1 )
#define REG_R_ADDR		( 0x2 )
#define REG_R_INIT		( 0x3 )


#define MAX_ADDR 2048
#define NOTHING	0
#define STATUS	1
#define COMMAND_MEAS 2
#define TRUE	1
#define FALSE	0
#define INIT	0
#define ARRAY_LENGHT 769


//	F	U	N	K	T	I	O	N	E	N

/************************************************************************/
/*
 *	void sendCommand(cmd)
 *	Funktion welche einen Befehl sendet
 * 	Erst wird das Register mit der Nummer des Befehles beschrieben und
 * 	danach wird das Register sofort wieder geloescht, da sonst
 * 	permanent der Befehl gesendet werden wuerde.
 *
 */
/************************************************************************/
void sendCommand(volatile uint32_t *base_addr,  uint32_t cmd);

/************************************************************************/
/*
 *	void initMemory
 *	Der Gesamte Speicher wird initialisiert.
 *
 */
/************************************************************************/
void initMemory(volatile uint32_t *base_addr );

/************************************************************************/
/*
 *	int findBeginOfData(int offset)
 *	Diese Funktion findet den Begin von Daten aus dem Speicher.
 *	Sie prueft alle stellen des Speichers auf die aufeinander
 *	folgenden Inhalte 'M' und 'S' welche den Anfang eines Befehls
 *	markieren.
 *	Die Position des 'M' wird dann zur�ckgeliefert.
 *	Mit dem Parameter : 'int offset'
 *	kann die Stelle uebergeben an der begonnen werden soll zu suchen
 *
 *************************************************************************/
uint32_t findBeginOfData(volatile uint32_t *base_addr, uint32_t offset);

/************************************************************************/
/*
 *	int findEndOfData(int begin)
 *	Diese Funktion findet ausgehend vom Anfang des Befehls das Ende des
 *	gleichen.
 *	Die Funktion prueft alle stellen des Speichers auf die aufeinander
 *	folgenden Inhalte 'LF' und 'LF' welche das Ende eines Befehls
 *	markieren.
 *	Die Position des letzten Zeichens des Befehls 'LF' wird
 *	zurueckgegeben.
 *	Mit dem Parameter : 'int begin'
 *	muss die Stelle uebergeben werden an der die Daten des Befehls beginnen
 *
 *************************************************************************/
uint32_t findEndOfData(volatile uint32_t *base_addr, uint32_t begin);

/************************************************************************/
/*
 *	void printData(int begin, int end)
 *	Diese Funktion gibt den Inhalt des Speichers zwischen den Uebergabe
 *	Parametern begin und end aus.
 *
 *************************************************************************/
void printData(volatile uint32_t *base_addr, uint32_t begin, uint32_t end);

/************************************************************************/
/*
 *	int getBeginDistanceData(int beginData, int endData)
 *	Da eine Beispielhafte Antwort des Laser wie folgt aussieht:
 *
 *	|	Befehlswiederholung	|	ErrorCode	|	TimeStamp	|	Data				|
 *	|MS 0380 0390 20 00 	|	LF 99b		|	LF 0<m2;	|LF 06b06X06W06W06V06^0	|LF LF
 *
 *	Muss der Anfang des Databereichs gesondert detektiert werden und dazu dient diese Funktion
 *	Mit den Parametern 'int beginData' und 'int endData' werden die Stellen im Speicher
 *	uebergeben an denen der Andfang und das Ende der Laserantwort stehen.
 *
 *************************************************************************/
uint32_t getBeginDistanceData(volatile uint32_t *base_addr, uint32_t beginData, uint32_t endData);

/************************************************************************/
/*
 *	int encodingDistance(int dataPos)
 *	Um die Daten in Distanzen umzuwandeln wird diese Funktion benutzt.
 *	Gemaess des Uebertragungsprotokolls des Lasers werden die gespeicherten
 *	Buchstaben in Entfernungen in Millimeter umgerechnet.
 *
 *************************************************************************/
uint32_t encodingDistance(volatile uint32_t *base_addr, uint32_t dataPos);

/************************************************************************/
/*
 *	void printDistances(int begin, int end)
 *	Diese Funktion gibt die umgerechneten Distanzen auf der Console aus.
 *
 *************************************************************************/
void printDistances(volatile uint32_t *base_addr, uint32_t begin, uint32_t end);

/************************************************************************/
/*
 *	void printDistances2(uint16_t *array)
 *	Diese Funktion gibt den Inhalt des Arrays aus.
 *
 *************************************************************************/
void printDistances2(uint16_t *array);

/************************************************************************/
/*
 *	uint8_t fillArrayDistances(uint32_t begin, uint32_t end, uint16_t *array)
 *	
 *	Das Array uint16_t *array wird mit den Distanzen zwischen  uint32_t begin
 *	und uint32_t end bef�llt.
 *
 *************************************************************************/
void fillArrayDistances(volatile uint32_t *base_addr, uint32_t begin, uint32_t end, uint16_t *array);

/************************************************************************/
/*
 *	@brief		uint8_t doMeasurement(uint16_t *distance)
 *
 *	@details	Diesen Befehl benutzen um eine Messung durchzuf�hren und Messwerte
 *				in einem array zu speichern
 *
 *	@param		uint16_t *distance	Array in das die Messwerte eingef�gt werden
 *
 *	@retval		0	Alles Okay
 *				1	Fehler
 *
 *
 *************************************************************************/
uint8_t doMeasurement(volatile uint32_t *base_addr, uint16_t *distance);

/************************************************************************/
/*
 *	@brief		uint8_t doMeasurement_laser(void)
 *
 *	@details	Diesen Befehl nutzt man um auf den DE0_NANO_SOC eine Messung
 *				zu strten
 *
 *	@param		keine
 *
 *	@retval		0	Alles Okay
 *				1	Fehler
 *
 *
 *************************************************************************/
uint8_t doMeasurement_laser(void);
#endif
