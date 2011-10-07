	org 0800h
	#define povsegs1 	43			;Constant for number of segments in string 1
	#define	povsegs2	91			;Constang for number of segments in string 2
	#define	povsegs3	57 
	
pov_table ;table containing locations of pov character strings and lengths
	de	0x03
	de	0x45,0x00,0x08,0x0C	;string 1 pov length and location
	de	0x5B,0x00,0x08,0x57	;string 2 pov length and location
	de	0x39,0x00,0x08,0xBB	;string 3 pov length and location	
end_table

pov_string1 ;pov character data (string 1)
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
 	de 0x7F,0x10,0x8,0x4,0x7F,0x0		;N
 	de 0x7F,0x49,0x49,0x36,0x0			;B
 	de 0x2F,0x0							;i
 	de 0x10,0x3F,0x10,0x0				;t
 	de 0x7E,0x1,0xE,0x1,0x7E,0x0		;W
 	de 0x1F,0x11,0x11,0x1F,0x0			;o
 	de 0x1F,0x10,0x10,0x1F,0x0			;n
 	de 0x1F,0x11,0x11,0x7F,0x0			;d
 	de 0xE,0x15,0x15,0xD,0x0			;e
 	de 0x1F,0x8,0x10,0x10				;r
 	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
end_string1

pov_string2	;pov character data (string 2)
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x7F,0x41,0x49,0x49,0x4F,0x00	;G
	de	0x7F,0x49,0x49,0x41,0x00		;E
	de	0x7F,0x41,0x41,0x41,0x7F,0x00	;O
	de	0x7F,0x48,0x48,0x48,0x37,0x00	;R
	de	0x7F,0x41,0x49,0x49,0x4F,0x00	;G
	de	0x7F,0x49,0x49,0x41,0x00		;E
	de	0x00,0x00,0x00
	de	0x7F,0x08,0x08,0x08,0x7F,0x00	;H
	de	0x3F,0x44,0x44,0x44,0x3F,0x00	;A
	de	0x7F,0x41,0x41,0x41,0x3E,0x00	;D
	de	0x7F,0x01,0x01,0x01,0x00		;L
	de	0x7F,0x49,0x49,0x41,0x00		;E
	de	0x70,0x08,0x0F,0x08,0x70,0x00	;Y
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
end_string2

pov_string3 ;pov character data (string 3)
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x7F,0x41,0x41,0x41,0x00		;C
	de	0x0E,0x11,0x11,0x12,0x0F,0x00	;a
	de	0x1F,0x10,0x10,0x10,0x00		;r
	de	0x1F,0x11,0x11,0x7F,0x00		;d
	de	0x7F,0x48,0x48,0x78,0x00		;P
	de	0x7F,0x41,0x41,0x41,0x7F,0x00	;O
	de	0x7C,0x02,0x01,0x02,0x7C		;V
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
	de	0x00,0x00,0x00,0x00,0x00		;Buffer
end_string3