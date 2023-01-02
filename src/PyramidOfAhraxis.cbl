       >>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. PYRAMIDOFAHRAXIS.

DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 GAMEDATA.
          02 SCORE PIC 9999.
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
       MOVE 0 TO SCORE
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
           WHEN "e" WHEN "E"
               GO TO GOEAST
           WHEN "m" WHEN "M"
               GO TO GAMEMENU
           WHEN "n" WHEN "N"
               GO TO GONORTH
           WHEN "s" WHEN "S"
               GO TO GOSOUTH
           WHEN "w" WHEN "W"
               GO TO GOWEST
           WHEN OTHER
               PERFORM INVALIDCOMMAND
               GO TO GAMELOOP
       END-EVALUATE.

GOEAST.
       EVALUATE ROOMNUMBER
           WHEN 19
               MOVE 20 TO ROOMNUMBER
           WHEN 22
               MOVE 23 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GONORTH.
       EVALUATE ROOMNUMBER
           WHEN 1
               MOVE 19 TO ROOMNUMBER
           WHEN 22
               MOVE 1 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GOSOUTH.
       EVALUATE ROOMNUMBER
           WHEN 1
               MOVE 22 TO ROOMNUMBER
           WHEN 19
               MOVE 1 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GOWEST.
       IF ROOMNUMBER IS EQUAL TO 1 THEN 
           GO TO LEAVEDUNGEON
       END-IF
       PERFORM INVALIDCOMMAND
       GO TO GAMELOOP.

LEAVEDUNGEON.
       DISPLAY SPACE
       DISPLAY "YOU EXIT THE PYRAMID OF AHRAXIS ALIVE!"
       DISPLAY "YER SCORE IS : " SCORE
       GO TO MAINMENU.

INVALIDCOMMAND.
       DISPLAY SPACE
       DISPLAY "INVALID COMMAND."
       EXIT.
     

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

DESCRIBEROOM2.
       DISPLAY "ROOM2."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM3.
       DISPLAY "ROOM3."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM4.
       DISPLAY "ROOM4."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM5.
       DISPLAY "ROOM5."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM6.
       DISPLAY "ROOM6."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM7.
       DISPLAY "ROOM7."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM8.
       DISPLAY "ROOM8."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM9.
       DISPLAY "ROOM9."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM10.
       DISPLAY "ROOM10."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM11.
       DISPLAY "ROOM11."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM12.
       DISPLAY "ROOM12."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM13.
       DISPLAY "ROOM13."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM14.
       DISPLAY "ROOM14."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM15.
       DISPLAY "ROOM15."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM16.
       DISPLAY "ROOM16."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM17.
       DISPLAY "ROOM17."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM18.
       DISPLAY "ROOM18."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM19.
       DISPLAY "YOU ARE IN A PASSAGEWAY T-JUNCTION."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES EAST."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES WEST."
       MOVE "NYYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM20.
       DISPLAY "ROOM20."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM21.
       DISPLAY "ROOM21."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM22.
       DISPLAY "YOU ARE IN A PASSAGEWAY T-JUNCTION."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES NORTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES EAST."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES WEST."
       MOVE "YYNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM23.
       DISPLAY "ROOM23."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM24.
       DISPLAY "ROOM24."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM25.
       DISPLAY "ROOM25."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM26.
       DISPLAY "ROOM26."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM27.
       DISPLAY "ROOM27."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM28.
       DISPLAY "ROOM28."
       MOVE "NNNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM.
       EVALUATE ROOMNUMBER
           WHEN 1
               PERFORM DESCRIBEROOM1
           WHEN 2
               PERFORM DESCRIBEROOM2
           WHEN 3
               PERFORM DESCRIBEROOM3
           WHEN 4
               PERFORM DESCRIBEROOM4
           WHEN 5
               PERFORM DESCRIBEROOM5
           WHEN 6
               PERFORM DESCRIBEROOM6
           WHEN 7
               PERFORM DESCRIBEROOM7
           WHEN 8
               PERFORM DESCRIBEROOM8
           WHEN 9
               PERFORM DESCRIBEROOM9
           WHEN 10
               PERFORM DESCRIBEROOM10
           WHEN 11
               PERFORM DESCRIBEROOM11
           WHEN 12
               PERFORM DESCRIBEROOM12
           WHEN 13
               PERFORM DESCRIBEROOM13
           WHEN 14
               PERFORM DESCRIBEROOM14
           WHEN 15
               PERFORM DESCRIBEROOM15
           WHEN 16
               PERFORM DESCRIBEROOM16
           WHEN 17
               PERFORM DESCRIBEROOM17
           WHEN 18
               PERFORM DESCRIBEROOM18
           WHEN 19
               PERFORM DESCRIBEROOM19
           WHEN 20
               PERFORM DESCRIBEROOM20
           WHEN 21
               PERFORM DESCRIBEROOM21
           WHEN 22
               PERFORM DESCRIBEROOM22
           WHEN 23
               PERFORM DESCRIBEROOM23
           WHEN 24
               PERFORM DESCRIBEROOM24
           WHEN 25
               PERFORM DESCRIBEROOM25
           WHEN 26
               PERFORM DESCRIBEROOM26
           WHEN 27
               PERFORM DESCRIBEROOM27
           WHEN 28
               PERFORM DESCRIBEROOM28
       END-EVALUATE
       EXIT.
