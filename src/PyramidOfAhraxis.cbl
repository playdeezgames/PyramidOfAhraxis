       >>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. PYRAMIDOFAHRAXIS.

DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 GAMEDATA.
          02 ROOMNUMBER PIC 99.
       01 SCRATCHPAD.
          02 COMMAND PIC X.
          02 AVAILABLECOMMANDS.
             03 DIRECTIONCOMMANDS.
                04 NORTH PIC X VALUE "N".
                   88 CANGONORTH VALUE "Y".
                04 EAST PIC X VALUE "N".
                   88 CANGOEAST VALUE "Y".
                04 SOUTH PIC X VALUE "N".
                   88 CANGOSOUTH VALUE "Y".
                04 WEST PIC X VALUE "N".
                   88 CANGOWEST VALUE "Y".
                       
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
       MOVE 1 TO ROOMNUMBER
       GO TO GAMELOOP.

GAMELOOP.
       DISPLAY SPACE
       PERFORM DESCRIBEROOM
       DISPLAY "AVAILABLE COMMANDS: "
       IF CANGONORTH THEN 
           DISPLAY "GO [N]ORTH"
       END-IF
       IF CANGOEAST THEN 
           DISPLAY "GO [E]AST"
       END-IF
       IF CANGOSOUTH THEN 
           DISPLAY "GO [S]OUTH"
       END-IF
       IF CANGOWEST THEN 
           DISPLAY "GO [W]EST"
       END-IF
       DISPLAY "GAME [M]ENU"
       DISPLAY SPACE
       ACCEPT COMMAND
       EVALUATE COMMAND
           WHEN "m" WHEN "M"
               GO TO GAMEMENU
       END-EVALUATE
       GO TO GAMELOOP.

GAMEMENU.
       DISPLAY SPACE
       DISPLAY "GAME MENU:"
       DISPLAY "[C]ONTINUE GAME"
       DISPLAY "[A]BANDON GAME"
       ACCEPT COMMAND
       EVALUATE COMMAND
           WHEN "c" WHEN "C"
               GO TO GAMELOOP
           WHEN "a" WHEN "A"
               GO TO CONFIRMABANDON
       END-EVALUATE
       GO TO GAMEMENU.

CONFIRMABANDON.
       DISPLAY SPACE 
       DISPLAY "ARE YOU SURE YOU WANT TO ABANDON THE GAME?"
       DISPLAY "[Y]ES"
       DISPLAY "[N]O"
       ACCEPT COMMAND
       IF COMMAND IS EQUAL TO "Y" OR COMMAND IS EQUAL TO "y" THEN 
           GO TO MAINMENU
       END-If
       GO TO GAMEMENU.

DESCRIBEROOM1.
       DISPLAY "YER IN A TWENTY FIVE FOOT BY FIFTEEN FOOT CHAMBER."
       DISPLAY "THERE ARE TWO ROWS OF FOUR COLUMNS IN THE MIDDLE OF THE CHAMBER."
       DISPLAY "TO THE WEST THERE ARE STAIRS LEADING OUTSIDE."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES NORTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES SOUTH."
       MOVE "YNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM.
       EVALUATE ROOMNUMBER
           WHEN 1
               PERFORM DESCRIBEROOM1
       END-EVALUATE
       EXIT.
