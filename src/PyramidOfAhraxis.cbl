       >>SOURCE FORMAT FREE
IDENTIFICATION DIVISION.
PROGRAM-ID. PYRAMIDOFAHRAXIS.

DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 GAMEDATA.
          02 SCORE PIC 9999.
          02 ROOMNUMBER PIC 99.
          02 CHARACTERSHEET.
             03 STRENGTH PIC 99.
             03 DEXTERITY PIC 99.
             03 CONSTITUTION PIC 99.
             03 INTELLIGENCE PIC 99.
             03 WISDOM PIC 99.
             03 CHARISMA PIC 99.
             03 HITPOINTS PIC 99.
             03 MAXIMUMHITPOINTS PIC 99.
          02 VISITFLAGS OCCURS 28 TIMES.
             03 VISITFLAG PIC X VALUE "N".
                88 HASVISITED VALUE "Y".
                88 HASNOTVISITED VALUE "N".
          02 ITEMS.
             03 ROOMITEMCOUNT PIC 99.
             03 INVENTORYITEMCOUNT PIC 99.
             03 SHIELD PIC 99.
                88 INHAND VALUE 99.
       01 SCRATCHPAD.
          02 RNGSEEDDATA PIC 999.
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
             03 VERBS.
                04 TAKE PIC X VALUE "N".
                   88 CANTAKE VALUE "Y".
                       
PROCEDURE DIVISION.
       COMPUTE RNGSEEDDATA = FUNCTION RANDOM(FUNCTION SECONDS-PAST-MIDNIGHT()).
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

ROLLUPCHARACTER.
       COMPUTE STRENGTH = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE DEXTERITY = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE CONSTITUTION = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE INTELLIGENCE = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE WISDOM = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE CHARISMA = FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + FUNCTION RANDOM() * 6 + 3
       COMPUTE MAXIMUMHITPOINTS = FUNCTION RANDOM() * 8
       MOVE MAXIMUMHITPOINTS TO HITPOINTS
       EXIT.

STARTGAME.
       DISPLAY SPACE 
       DISPLAY "AHRAXIS IS LONG DEAD, BUT PEOPLE ARE STILL AFRAID TO COME CLOSE TO THE PYRAMID."
       DISPLAY "THESE DAYS IT IS OVERRUN WITH PIGEONS, WHICH DON'T CARE ABOUT THE PAST OF THE PLACE."
       DISPLAY "RUMORS SAY THAT UNTOLD TREASURES OF GOLD AND JEWELS AND MAGICAL ARTIFACTS ARE STORED HERE."
       PERFORM ROLLUPCHARACTER
       PERFORM RESETITEMS
       MOVE 0 TO SCORE
       PERFORM CLEARVISITFLAG VARYING ROOMNUMBER FROM 1 BY 1 UNTIL ROOMNUMBER IS GREATER THAN 28
       MOVE 1 TO ROOMNUMBER
       GO TO GAMELOOP.

RESETITEMS.
       MOVE 14 TO SHIELD
       EXIT.

CLEARVISITFLAG.
       SET HASNOTVISITED(ROOMNUMBER) TO TRUE
       EXIT.

SETVISITFLAG.
       IF HASNOTVISITED(ROOMNUMBER) THEN
           ADD 1 TO SCORE
           SET HASVISITED(ROOMNUMBER) TO TRUE
       END-IF
       EXIT.

GAMELOOP.
       PERFORM SETVISITFLAG
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
       IF CANTAKE THEN 
           DISPLAY "[T]AKE ITEM"
       END-IF
       PERFORM UPDATEINVENTORYITEMCOUNT
       IF INVENTORYITEMCOUNT IS GREATER THAN 0 THEN 
           DISPLAY "[I]NVENTORY"
       END-IF
       DISPLAY "GAME [M]ENU"
       DISPLAY SPACE
       DISPLAY "NOW WHAT? " WITH NO ADVANCING
       ACCEPT COMMAND
       EVALUATE COMMAND
           WHEN "c" WHEN "C"
               GO TO DESCRIBECHARACTER
           WHEN "e" WHEN "E"
               GO TO GOEAST
           WHEN "m" WHEN "M"
               GO TO GAMEMENU
           WHEN "n" WHEN "N"
               GO TO GONORTH
           WHEN "s" WHEN "S"
               GO TO GOSOUTH
           WHEN "t" WHEN "T"
               GO TO TAKEITEM
           WHEN "w" WHEN "W"
               GO TO GOWEST
           WHEN OTHER
               PERFORM INVALIDCOMMAND
               GO TO GAMELOOP
       END-EVALUATE.

UPDATEINVENTORYITEMCOUNT.
       MOVE 0 TO INVENTORYITEMCOUNT
       IF INHAND OF SHIELD THEN 
           ADD 1 TO INVENTORYITEMCOUNT
       END-IF
       EXIT.

TAKEITEM.
       IF ROOMITEMCOUNT IS EQUAL TO 0 THEN 
           PERFORM INVALIDCOMMAND
           GO TO GAMELOOP
       END-IF
       IF ROOMITEMCOUNT IS EQUAL TO 1 THEN 
           GO TO TAKESINGLEITEM
       END-IF
       GO TO GAMELOOP.

TAKESINGLEITEM.
       IF SHIELD IS EQUAL TO ROOMNUMBER THEN 
           SET INHAND OF SHIELD TO TRUE
           GO TO GAMELOOP
       END-IF
       GO TO GAMELOOP.

GOEAST.
       EVALUATE ROOMNUMBER
           WHEN 2
               MOVE 3 TO ROOMNUMBER
           WHEN 6
               MOVE 5 TO ROOMNUMBER
           WHEN 9
               MOVE 8 TO ROOMNUMBER
           WHEN 10
               MOVE 9 TO ROOMNUMBER
           WHEN 11
               MOVE 14 TO ROOMNUMBER
           WHEN 12
               MOVE 11 TO ROOMNUMBER
           WHEN 13
               MOVE 12 TO ROOMNUMBER
           WHEN 14
               MOVE 26 TO ROOMNUMBER
           WHEN 15
               MOVE 14 TO ROOMNUMBER
           WHEN 16
               MOVE 4 TO ROOMNUMBER
           WHEN 17
               MOVE 16 TO ROOMNUMBER
           WHEN 18
               MOVE 19 TO ROOMNUMBER
           WHEN 19
               MOVE 20 TO ROOMNUMBER
           WHEN 21
               MOVE 22 TO ROOMNUMBER
           WHEN 22
               MOVE 23 TO ROOMNUMBER
           WHEN 24
               MOVE 25 TO ROOMNUMBER
           WHEN 27
               MOVE 28 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GONORTH.
       EVALUATE ROOMNUMBER
           WHEN 1
               MOVE 19 TO ROOMNUMBER
           WHEN 3
               MOVE 17 TO ROOMNUMBER
           WHEN 4
               MOVE 5 TO ROOMNUMBER
           WHEN 6
               MOVE 7 TO ROOMNUMBER
           WHEN 11
               MOVE 21 TO ROOMNUMBER
           WHEN 14
               MOVE 25 TO ROOMNUMBER
           WHEN 15
               MOVE 28 TO ROOMNUMBER
           WHEN 16
               MOVE 6 TO ROOMNUMBER
           WHEN 18
               MOVE 8 TO ROOMNUMBER
           WHEN 20
               MOVE 2 TO ROOMNUMBER
           WHEN 22
               MOVE 1 TO ROOMNUMBER
           WHEN 24
               MOVE 23 TO ROOMNUMBER
           WHEN 27
               MOVE 26 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GOSOUTH.
       EVALUATE ROOMNUMBER
           WHEN 1
               MOVE 22 TO ROOMNUMBER
           WHEN 2
               MOVE 20 TO ROOMNUMBER
           WHEN 5
               MOVE 4 TO ROOMNUMBER
           WHEN 6
               MOVE 16 TO ROOMNUMBER
           WHEN 7
               MOVE 6 TO ROOMNUMBER
           WHEN 8
               MOVE 18 TO ROOMNUMBER
           WHEN 14
               MOVE 15 TO ROOMNUMBER
           WHEN 17
               MOVE 3 TO ROOMNUMBER
           WHEN 19
               MOVE 1 TO ROOMNUMBER
           WHEN 21
               MOVE 11 TO ROOMNUMBER
           WHEN 23
               MOVE 24 TO ROOMNUMBER
           WHEN 25
               MOVE 14 TO ROOMNUMBER
           WHEN 26
               MOVE 27 TO ROOMNUMBER
           WHEN 28
               MOVE 15 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

GOWEST.
       EVALUATE ROOMNUMBER
           WHEN 1
               GO TO LEAVEDUNGEON
           WHEN 3
               MOVE 2 TO ROOMNUMBER
           WHEN 4
               MOVE 16 TO ROOMNUMBER
           WHEN 5
               MOVE 6 TO ROOMNUMBER
           WHEN 8
               MOVE 9 TO ROOMNUMBER
           WHEN 9
               MOVE 10 TO ROOMNUMBER
           WHEN 11
               MOVE 12 TO ROOMNUMBER
           WHEN 12
               MOVE 13 TO ROOMNUMBER
           WHEN 14
               MOVE 11 TO ROOMNUMBER
           WHEN 16
               MOVE 17 TO ROOMNUMBER
           WHEN 19
               MOVE 18 TO ROOMNUMBER
           WHEN 20
               MOVE 19 TO ROOMNUMBER
           WHEN 22
               MOVE 21 TO ROOMNUMBER
           WHEN 23
               MOVE 22 TO ROOMNUMBER
           WHEN 25
               MOVE 24 TO ROOMNUMBER
           WHEN 26
               MOVE 14 TO ROOMNUMBER
           WHEN 28
               MOVE 27 TO ROOMNUMBER
           WHEN OTHER
               PERFORM INVALIDCOMMAND
       END-EVALUATE
       GO TO GAMELOOP.

LEAVEDUNGEON.
       DISPLAY SPACE
       ADD 1 TO SCORE
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

DESCRIBECHARACTER.
       DISPLAY SPACE 
       DISPLAY "YER CHARACTER:"
       DISPLAY "STR: " STRENGTH
       DISPLAY "DEX: " DEXTERITY
       DISPLAY "CON: " CONSTITUTION
       DISPLAY "INT: " INTELLIGENCE
       DISPLAY "WIS: " WISDOM
       DISPLAY "CHA: " CHARISMA
       DISPLAY "HP: " HITPOINTS "/" MAXIMUMHITPOINTS
       GO TO GAMELOOP.

DESCRIBEROOM1.
       DISPLAY "YER IN A TWENTY-FIVE BY FIFTEEN FOOT CHAMBER."
       DISPLAY "THERE ARE TWO ROWS OF FOUR COLUMNS EVENLY SPACED."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES NORTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES SOUTH."
       DISPLAY "TO THE WEST THERE ARE STAIRS LEADING OUTSIDE."
       MOVE "YNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM2.
       DISPLAY "YER IN A FIFTEEN BY FIFTEEN FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       DISPLAY "THERE IS A DOOR TO THE SOUTH."
       MOVE "NYYN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM3.
       DISPLAY "YER IN A FIFTEEN BY FIFTEEN FOOT CHAMBER."
       DISPLAY "THERE IS A DOOR TO THE NORTH."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "YNNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM4.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY FOOT CHAMBER."
       DISPLAY "THERE IS A DOUBLE DOOR TO THE NORTH."
       DISPLAY "THERE IS AN OPEN PORTCULLIS TO THE WEST."
       MOVE "YNNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM5.
       DISPLAY "YER IN A FIFTEEN BY FIFTEEN FOOT CHAMBER."
       DISPLAY "THERE IS A DOUBLE DOOR TO THE SOUTH."
       DISPLAY "THERE IS A DOOR TO THE WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM6.
       DISPLAY "YER IN A TWENTY-FIVE BY THIRTY FOOT CHAMBER."
       DISPLAY "THERE ARE TWO ROWS OF FIVE COLUMNS NEAR THE EAST AND WEST WALLS."
       DISPLAY "THERE IS A DOOR TO THE NORTH"
       DISPLAY "THERE IS A DOOR TO THE EAST"
       DISPLAY "THERE IS A DOOR TO THE SOUTH"
       MOVE "YYYN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM7.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY FOOT CHAMBER."
       DISPLAY "THERE IS A PUDDLE OF WATER IN THE NORTHWEST CORNER."
       DISPLAY "THERE IS A CRATE HERE."
       DISPLAY "THERE IS A DOOR TO THE SOUTH."
       MOVE "NNYN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM8.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM9.
       DISPLAY "YER IN A THIRTY-FIVE BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "NYNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM10.
       DISPLAY "YER IN A TWENTY BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       MOVE "NYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM11.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE NORTH."
       DISPLAY "THERE IS A DOOR TO THE EAST."
       MOVE "YYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM12.
       DISPLAY "YER IN A THIRTY-FIVE BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "NYNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM13.
       DISPLAY "YER IN A TWENTY BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       MOVE "NYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM14.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY-FIVE FOOT CHAMBER."
       DISPLAY "THERE IS A DOOR TO THE NORTH."
       DISPLAY "THERE IS A PASSAGEWAY TO THE EAST."
       DISPLAY "THERE IS A PASSAGEWAY TO THE SOUTH."
       DISPLAY "THERE IS A DOOR TO THE WEST."
       MOVE "YYYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM15.
       DISPLAY "YER IN A TWENTY-FIVE BY TWENTY FIVE FOOT CHAMBER."
       DISPLAY "THERE ARE TWO ROWS OF FOUR COLUMNS ALONE THE EAST AND WEST WALLS."
       DISPLAY "THERE IS A PUDDLE IN THE NORTHEAST CORNER."
       DISPLAY "THERE IS A PASSAGEWAY TO THE NORTH."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "YNNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM16.
       DISPLAY "YER IN A NORTH-SOUTH HALLWAYS THAT ENDS IN A T TO THE SOUTH."
       DISPLAY "THERE IS A DOOR GOING NORTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       DISPLAY "THERE IS A PASSAGEWAY GOING WEST."
       MOVE "YYNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM17.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       DISPLAY "THERE IS A DOOR GOING SOUTH."
       MOVE "NYYN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM18.
       DISPLAY "YER IN A NORTH-SOUTH HALLWAY THAT ENDS IN AN ELBOW ON THE SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING NORTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       MOVE "YYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM19.
       DISPLAY "YOU ARE IN A PASSAGEWAY T-JUNCTION."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES EAST."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES WEST."
       MOVE "NYYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM20.
       DISPLAY "YOU ARE IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A DOOR TO THE NORTH."
       DISPLAY "THERE IS A PASSAGEWAY TO THE WEST."
       MOVE "YNNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM21.
       DISPLAY "YER IN A NORTH-SOUTH HALLWAY WITH AN ELBOW ON THE NORTH END."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       DISPLAY "THERE IS A PASSAGEWAY GOING SOUTH."
       MOVE "NYYN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM22.
       DISPLAY "YOU ARE IN A PASSAGEWAY T-JUNCTION."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES NORTH."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES EAST."
       DISPLAY "THERE IS A PASSAGEWAY THAT GOES WEST."
       MOVE "YYNY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM23.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM24.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING NORTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       MOVE "YYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM25.
       DISPLAY "YER IN A NORTH-SOUTH HALLWAY WITH AN ELBOW ON THE NORTH END."
       DISPLAY "THERE IS A DOOR GOING SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM26.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM27.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING NORTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING EAST."
       MOVE "YYNN" TO DIRECTIONCOMMANDS
       EXIT.

DESCRIBEROOM28.
       DISPLAY "YER IN AN ELBOW PASSAGE."
       DISPLAY "THERE IS A PASSAGEWAY GOING SOUTH."
       DISPLAY "THERE IS A PASSAGEWAY GOING WEST."
       MOVE "NNYY" TO DIRECTIONCOMMANDS
       EXIT.

RESETVERBS.
       MOVE "N" TO VERBS
       EXIT.

DESCRIBEROOM.
       PERFORM RESETVERBS
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
       PERFORM DESCRIBEROOMITEMS
       EXIT.

DESCRIBEROOMITEMS.
       MOVE 0 TO ROOMITEMCOUNT
       IF SHIELD IS EQUAL TO ROOMNUMBER THEN 
           DISPLAY "THERE IS A SHIELD ON THE FLOOR."
           SET CANTAKE TO TRUE
           ADD 1 TO ROOMITEMCOUNT
       END-IF
       EXIT.
