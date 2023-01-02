       >>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. PYRAMIDOFAHRAXIS.

DATA DIVISION.
       WORKING-STORAGE SECTION.
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
       DISPLAY "************************************************************"
       DISPLAY SPACE
       DISPLAY "[S]TART GAME"
       DISPLAY "[I]NSTRUCTIONS"
       DISPLAY "[Q]UIT"
       ACCEPT COMMAND
       EVALUATE COMMAND
        WHEN "s" WHEN "S"
        WHEN "i" WHEN "I"
        WHEN "q" WHEN "Q"
           GO TO CONFIRMQUIT
        WHEN OTHER 
           GO TO TITLESCREEN
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
       GO TO TITLESCREEN.
