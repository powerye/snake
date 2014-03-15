#! /bin/bash

LINES=`tput lines`
COLUMNS=`tput cols`
SCORE=3
declare -A FIELD
SNAKE=()
HEAD="@"
BODY="*"
EGG="O"
TAIL=0

ConfigGame() {
    if [ $LINES -lt 5 ] || [ $COLUMNS -lt 16 ]
    then    echo Please extend your gamespace!
            exit
    fi

    echo -ne "[?25l"
}

InitField() {
    clear
    local i j

    for i in `seq $COLUMNS`
    do  for j in `seq $LINES`
        do  FIELD[${i}x$j]="EMPTY"
        done
    done

    for i in `seq $COLUMNS`
    do  echo -ne "[1;${i}H─"
        echo -ne "[$LINES;${i}H─"
        FIELD[${i}x1]="BORDER"
        FIELD[${i}x$LINES]="BORDER"
    done

    for i in `seq $LINES`
    do  echo -ne "[$i;1H│"
        echo -ne "[$i;${COLUMNS}H│"
        FIELD[1x$i]="BORDER"
        FIELD[${COLUMNS}x$i]="BORDER"
    done

    echo -ne "[1;5H score: $SCORE "
    echo -ne "[1;1H┌"
    echo -ne "[1;${COLUMNS}H┐"
    echo -ne "[$LINES;1H└"
    echo -ne "[$LINES;${COLUMNS}H┘"
}

NewEGG() {
    local x y

    while :
    do  x=$[$RANDOM%$COLUMNS]
        y=$[$RANDOM%$LINES]
        if [ "${FIELD[${x}x$y]}" == "EMPTY" ]
        then    echo -ne "[$y;${x}H$EGG"
                FIELD[${x}x$y]="EGG"
                break;
        fi
    done
}

InitSnake() {
    echo -ne "[2;2H$BODY"
    echo -ne "[2;3H$BODY"
    echo -ne "[2;4H$HEAD"
    FIELD[4x2]="HEAD"
    FIELD[3x2]="BODY"
    FIELD[2x2]="BODY"
    SNAKE+=(2)
    SNAKE+=(2)
    SNAKE+=(3)
    SNAKE+=(2)
    SNAKE+=(4)
    SNAKE+=(2)
}

InitGame() {
    ConfigGame
    InitField
    InitSnake
    NewEGG
}

GameOver() {
    local x=$[$COLUMNS/2-5]
    local y=$[$LINES/2-1]
    echo -e "[$y;${x}H┌─────────┐"
    echo -e "[$[$y+1];${x}H│GAME OVER│"
    echo -e "[$[$y+2];${x}H└─────────┘"
    echo -e "[?25h[$[$LINES-1];0H"
    kill -9 0
}

ButtonAccept() {
    local x=0
    local key

    trap "GameOver" INT TERM QUIT

    while read -s -n1 key
    do  if [ "$key" == "A" ] || [ "$key" == "w" ]
        then    kill -26 $1
        elif [ "$key" == "B" ] || [ "$key" == "s" ]
        then    kill -27 $1
        elif [ "$key" == "C" ] || [ "$key" == "d" ]
        then    kill -28 $1
        elif [ "$key" == "D" ] || [ "$key" == "a" ]
        then    kill -29 $1
        elif [ "$key" == "q" ]
        then    GameOver
        elif [ "$key" == "p" ]
        then    if [ $[$x%2] -eq 0 ]
                then    kill -19 $1
                else    kill -18 $1
                fi
                ((x++))
        else    :   
        fi
    done
}

OneStep() {			
    local x=${SNAKE[$TAIL]}
    local y=${SNAKE[$TAIL+1]}

    if [ "${FIELD[${1}x$2]}" == "EMPTY" ]
    then    FIELD[${1}x$2]="HEAD"
            FIELD[${x}x$y]="EMPTY"
            SNAKE+=($1)
            SNAKE+=($2)
            unset SNAKE[$TAIL]
            unset SNAKE[$TAIL+1]
            echo -ne "[$2;${1}H$HEAD"
            echo -ne "[$y;${x}H "
            ((TAIL+=2))
    elif [ "${FIELD[${1}x$2]}" == "EGG" ]
    then    FIELD[${1}x$2]="HEAD"
            ((SCORE++))
            SNAKE+=($1)
            SNAKE+=($2)
            echo -ne "[$2;${1}H$HEAD"
            echo -ne "[1;5H score: $SCORE "
            NewEGG
    else    GameOver
    fi
}

SnakeMove() {
    local SIGNAL=28
    local oldSIGNAL=28
    local x y z

    trap "SIGNAL=26" 26
    trap "SIGNAL=27" 27
    trap "SIGNAL=28" 28
    trap "SIGNAL=29" 29

    while :
    do  y=${SNAKE[*]: -1}
        x=${SNAKE[*]: -2:1}

        case $SIGNAL in
        28|29)  if [ $oldSIGNAL -eq 28 ] || [ $oldSIGNAL -eq 29 ]
                then    SIGNAL=$oldSIGNAL
                fi;;
        27|26)  if [ $oldSIGNAL -eq 26 ] || [ $oldSIGNAL -eq 27 ]
                then    SIGNAL=$oldSIGNAL
                fi;;
            *)  ;;
        esac

        FIELD[${x}x$y]="BODY"
        echo -ne "[$y;${x}H$BODY"

        case $SIGNAL in
        28)	OneStep $[$x+1] $y;;
        29)	OneStep $[$x-1] $y;;
        27)	OneStep $x $[$y+1];;
        26)	OneStep $x $[$y-1];;
         *)	:;;
        esac

        oldSIGNAL=$SIGNAL
        sleep 0.05
    done
}

Start() {
    SnakeMove &
    ButtonAccept $!
}

InitGame
Start
