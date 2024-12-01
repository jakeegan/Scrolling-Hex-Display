# Scrolling Hex Display
An interrupt-based Nios II assembly-language program to receive character
data over UART and convert the data to a scrolling 7 segment hex display.

![](example.gif)

# Features
- One second timer interrupt based on a 50MHz clock shifts the display digits to the left
- Accepts external character codes over UART and converts it to the hex display using a lookup table

# Software Diagram
```

                         +-------+                                    +------+
                         |  Isr  |                                    | main |
                         +-------+                                    +------+
                       /           \                                      |
                      v             v                                     v
     +-------------------+        +-------------------+               +------+
     |    UartHandler    |        |   TimerHandler    |               | Init |
     +-------------------+        +-------------------+               +------+
        /              \                       \
       v                v                       v
+-----------+    +-----------------+   +-------------------+
| PrintChar |    | PrintHexDisplay |   | UpdateHexDisplay  |
+-----------+    +-----------------+   +-------------------+
```

# Running the program
1. Go to the emulator website at https://cpulator.01xz.net/
2. Choose Nios II DE0
3. Upload the source code
4. Compile and run
