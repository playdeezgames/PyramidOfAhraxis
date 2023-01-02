       >>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. PYRAMIDOFAHRAXIS.

DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 GAMEDATA.
          02 ROOMNUMBER PIC 99.
       01 SCRATCHPAD.
          02 COMMAND PIC X.
                       
PROCEDURE DIVISION.
TITLESCREEN.
       DISPLAY SPACE
       DISPLAY "************************************************************"
       DISPLAY "*                                                          *"
       DISPLAY "*                    PYRAMID OF AHRAXIS                    *"
       DISPLAY "*                                                          *"
       DISPLAY "*            A PRODUCTION OF THEGRUMPYGAMEDEV              *"
       DISPLAY "*            FOR INTERACTIVE FICTION GAME JAM              *"
       DISPLAY "*                                                          *"
       DISPLAY "************************************************************".
MAINMENU.
       DISPLAY SPACE
       DISPLAY "MAIN MENU:"
       DISPLAY "[S]TART GAME"
       DISPLAY "[I]NSTRUCTIONS"
       DISPLAY "[Q]UIT"
       ACCEPT COMMAND
       EVALUATE COMMAND
        WHEN "s" WHEN "S"
           GO TO STARTGAME
        WHEN "i" WHEN "I"
           GO TO INSTRUCTIONS
        WHEN "q" WHEN "Q"
           GO TO CONFIRMQUIT
        WHEN OTHER 
           GO TO MAINMENU
       END-EVALUATE.

CONFIRMQUIT.
       DISPLAY SPACE 
       DISPLAY "ARE YOU SURE YOU WANT TO QUIT?"
       DISPLAY "[Y]ES"
       DISPLAY "[N]O"
       ACCEPT COMMAND
       IF COMMAND="y" OR COMMAND="Y" THEN 
           STOP RUN
       END-IF
       GO TO MAINMENU.

INSTRUCTIONS.
       DISPLAY SPACE 
       DISPLAY "INSTRUCTIONS:"
       DISPLAY SPACE 
       DISPLAY "YOU ARE PRESENTED WITH A NUMBER OF SITUATIONS."
       DISPLAY "YER CHOICES ARE CLEARLY MARKED WITH BRACKETS []."
       DISPLAY "TYPE THE LETTER IN THE BRACKET AND PRESS ENTER"
       DISPLAY "TO DO THE THING!"
       GO TO MAINMENU.

STARTGAME.
       GO TO MAINMENU.
       